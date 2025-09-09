#include <jni.h>
#include <string>
#include <vector>
#include <cstdint>
#include <algorithm>
#include <random>
#include <chrono>
#include <cmath>

#include "llama.h"

// --- Estado global: solo el modelo; el contexto se crea por generación ---
static llama_model* g_model = nullptr;
static bool g_backend_inited = false;

// --- Utils: UTF-16 (Java) -> UTF-8 real (sin Modified UTF-8) ---
static std::string jstringToUtf8Strict(JNIEnv* env, jstring js) {
    if (!js) return {};
    jsize len16 = env->GetStringLength(js);
    const jchar* u16 = env->GetStringChars(js, nullptr);
    std::string out;
    out.reserve(len16 * 3);

    for (jsize i = 0; i < len16; ++i) {
        uint32_t c = u16[i];
        if (0xD800u <= c && c <= 0xDBFFu && i + 1 < len16) { // high surrogate
            uint32_t d = u16[i + 1];
            if (0xDC00u <= d && d <= 0xDFFFu) {
                c = 0x10000u + (((c - 0xD800u) << 10) | (d - 0xDC00u));
                ++i;
            }
        }
        if (c <= 0x7Fu) {
            out.push_back((char)c);
        } else if (c <= 0x7FFu) {
            out.push_back((char)(0xC0u | (c >> 6)));
            out.push_back((char)(0x80u | (c & 0x3Fu)));
        } else if (c <= 0xFFFFu) {
            out.push_back((char)(0xE0u | (c >> 12)));
            out.push_back((char)(0x80u | ((c >> 6) & 0x3Fu)));
            out.push_back((char)(0x80u | (c & 0x3Fu)));
        } else {
            out.push_back((char)(0xF0u | (c >> 18)));
            out.push_back((char)(0x80u | ((c >> 12) & 0x3Fu)));
            out.push_back((char)(0x80u | ((c >> 6) & 0x3Fu)));
            out.push_back((char)(0x80u | (c & 0x3Fu)));
        }
    }

    env->ReleaseStringChars(js, u16);
    return out;
}

// token -> texto (buffer dinámico)
static void append_token_piece(const llama_vocab* vocab, llama_token tok, std::string& out) {
    std::string buf(16, '\0');
    int need = llama_token_to_piece(vocab, tok, buf.data(), (int)buf.size(), 0, false);
    if (need < 0) return;
    if (need > (int)buf.size()) {
        buf.resize(need);
        need = llama_token_to_piece(vocab, tok, buf.data(), (int)buf.size(), 0, false);
        if (need < 0) return;
    }
    out.append(buf.data(), (size_t)need);
}

// Añade un token a un batch (API actual de llama.cpp)
static void batch_add_token(llama_batch& b, llama_token tok, int pos, bool want_logits) {
    const int n = b.n_tokens;
    b.token[n]     = tok;
    b.pos[n]       = pos;
    b.n_seq_id[n]  = 1;
    b.seq_id[n][0] = 0;
    b.logits[n]    = want_logits ? 1 : 0;
    b.n_tokens     = n + 1;
}

// Tokenización robusta: intenta con/ sin BOS y con/ sin especiales
static int32_t tokenize_robust(
    const llama_vocab* vocab,
    const std::string& text,
    bool add_bos,
    bool parse_special,
    std::vector<llama_token>& out_tokens)
{
    // 1) Sondeo
    int32_t n = llama_tokenize(
        vocab, text.c_str(), (int32_t)text.size(),
        nullptr, 0, add_bos, parse_special);

    if (n > 0) {
        out_tokens.resize(n);
        n = llama_tokenize(
            vocab, text.c_str(), (int32_t)text.size(),
            out_tokens.data(), n, add_bos, parse_special);
        if (n < 0) n = -n;
        if (n > 0) { out_tokens.resize(n); return n; }
    }

    // 2) Fallback con buffer amplio
    int32_t cap = (int32_t)text.size() + 64;
    if (cap < 64) cap = 64;
    out_tokens.assign(cap, 0);
    n = llama_tokenize(
        vocab, text.c_str(), (int32_t)text.size(),
        out_tokens.data(), cap, add_bos, parse_special);
    if (n < 0) n = -n;
    if (n > 0 && n <= cap) { out_tokens.resize(n); return n; }

    return -1;
}

// ------------ Sampling “clásico” (temp + top-k + top-p + repeat penalty) -----
struct SamplerParams {
    float temperature    = 0.8f;
    int   top_k          = 40;    // <=0 = desactivado
    float top_p          = 0.95f; // 0..1
    float repeat_penalty = 1.10f; // 1.0 = off
    int   repeat_last_n  = 64;    // cuántos tokens miramos para el penalty
};

static llama_token sample_token(
    const float* logits, int32_t n_vocab,
    const std::vector<llama_token>& recent,
    const SamplerParams& sp,
    std::mt19937& rng)
{
    // Copia y aplica penalties
    std::vector<float> cur(logits, logits + n_vocab);

    if (sp.repeat_penalty > 1.0f && !recent.empty()) {
        const int n = std::min((int)recent.size(), sp.repeat_last_n);
        for (int i = (int)recent.size() - n; i < (int)recent.size(); ++i) {
            const int id = (int)recent[i];
            if (id >= 0 && id < n_vocab) {
                // Penalización típica (ver llama.cpp): divide si logit > 0, multiplica si < 0
                cur[id] = (cur[id] < 0.0f) ? (cur[id] * sp.repeat_penalty)
                                           : (cur[id] / sp.repeat_penalty);
            }
        }
    }

    // Temperatura
    const float temp = std::max(0.05f, sp.temperature);
    for (int i = 0; i < n_vocab; ++i) cur[i] /= temp;

    // Top-k
    std::vector<int> idx(n_vocab);
    std::iota(idx.begin(), idx.end(), 0);
    if (sp.top_k > 0 && sp.top_k < n_vocab) {
        std::nth_element(idx.begin(), idx.begin() + sp.top_k, idx.end(),
                         [&](int a, int b){ return cur[a] > cur[b]; });
        idx.resize(sp.top_k);
    }

    // Softmax sobre candidatos
    std::vector<float> prob; prob.reserve(idx.size());
    float maxlog = -1e30f;
    for (int id : idx) maxlog = std::max(maxlog, cur[id]);
    float sum = 0.f;
    for (int id : idx) {
        float p = std::exp(cur[id] - maxlog);
        prob.push_back(p);
        sum += p;
    }
    for (float& p : prob) p /= (sum > 0.f ? sum : 1.f);

    // Top-p
    if (sp.top_p > 0.f && sp.top_p < 1.f) {
        // Ordenar por prob desc
        std::vector<int> order(prob.size());
        std::iota(order.begin(), order.end(), 0);
        std::sort(order.begin(), order.end(),
                  [&](int a, int b){ return prob[a] > prob[b]; });
        float cum = 0.f;
        size_t keep = 0;
        for (; keep < order.size(); ++keep) {
            cum += prob[order[keep]];
            if (cum >= sp.top_p) { ++keep; break; }
        }
        // Recompactar
        std::vector<int> idx2; idx2.reserve(keep);
        std::vector<float> prob2; prob2.reserve(keep);
        float s2 = 0.f;
        for (size_t i = 0; i < keep; ++i) {
            idx2.push_back(idx[order[i]]);
            prob2.push_back(prob[order[i]]);
            s2 += prob2.back();
        }
        for (float& p : prob2) p /= (s2 > 0.f ? s2 : 1.f);
        idx.swap(idx2);
        prob.swap(prob2);
    }

    // Muestreo categórico
    std::discrete_distribution<int> dist(prob.begin(), prob.end());
    int pick = dist(rng);
    return (llama_token)idx[pick];
}

// --------------------------- JNI ---------------------------------------------

extern "C" JNIEXPORT jboolean JNICALL
Java_com_learnsynth_learnsynth_1offline_1llm_LlamaJNI_loadModel(
        JNIEnv* env, jclass, jstring jpath) {

    if (!g_backend_inited) {
        llama_backend_init();
        g_backend_inited = true;
    }

    const std::string path = jstringToUtf8Strict(env, jpath);
    if (path.empty()) return JNI_FALSE;

    if (g_model) { llama_model_free(g_model); g_model = nullptr; }

    llama_model_params mp = llama_model_default_params();
    g_model = llama_model_load_from_file(path.c_str(), mp);
    return g_model ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_learnsynth_learnsynth_1offline_1llm_LlamaJNI_generate(
        JNIEnv* env, jclass,
        jstring juser, jstring jsystem,
        jint jmax_tokens, jfloat jtemp, jfloat jtop_p, jint jtop_k,
        jfloat jrepeat_penalty, jint jrepeat_last_n, jint jseed) {

    if (!g_model) {
        return env->NewStringUTF("ERROR: model not initialized");
    }

    const std::string user = jstringToUtf8Strict(env, juser);
    const std::string system = jstringToUtf8Strict(env, jsystem);
    const int max_tokens = std::max(1, (int)jmax_tokens);

    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = 2048;
    cp.n_batch = 512;
    cp.n_threads = 4;
    cp.n_threads_batch = cp.n_threads;

    llama_context* ctx = llama_init_from_model(g_model, cp);
    if (!ctx) return env->NewStringUTF("ERROR: failed to create context");

    const llama_vocab* vocab = llama_model_get_vocab(g_model);
    if (!vocab) {
        llama_free(ctx);
        return env->NewStringUTF("ERROR: vocab=null");
    }
    const int32_t n_vocab = llama_vocab_n_tokens(vocab);

    // Construir prompt con plantilla del modelo
    std::string prompt;
    {
        std::vector<llama_chat_message> chat;
        if (!system.empty()) chat.push_back({"system", system.c_str()});
        chat.push_back({"user", user.c_str()});
        // pasada 1: tamaño requerido (incluye '\0')
        int32_t need = llama_chat_apply_template(
            /*tmpl*/ nullptr,
            /*chat*/ chat.data(),
            /*n_msg*/ chat.size(),
            /*add_ass*/ true,
            /*buf*/ nullptr,
            /*length*/ 0
        );
        if (need <= 0) {
            prompt = system + user;
        } else {
            prompt.resize(need);
            llama_chat_apply_template(
                /*tmpl*/ nullptr,
                /*chat*/ chat.data(),
                /*n_msg*/ chat.size(),
                /*add_ass*/ true,
                /*buf*/ prompt.data(),
                /*length*/ (int32_t)prompt.size()
            );
        }
    }

    // Tokenización robusta
    std::vector<llama_token> inp;
    bool ok = false;
    for (bool add_bos : {false, true}) {
        for (bool parse_special : {true, false}) {
            if (tokenize_robust(vocab, prompt, add_bos, parse_special, inp) > 0) {
                ok = true;
                break;
            }
        }
        if (ok) break;
    }
    if (!ok) {
        llama_free(ctx);
        return env->NewStringUTF("ERROR: failed to tokenize (all modes)");
    }

    // Alimentar prompt
    llama_batch batch = llama_batch_init(std::max<int>(inp.size(), 32), 0, 1);
    for (int i = 0; i < (int)inp.size(); ++i) {
        batch_add_token(batch, inp[i], /*pos*/ i, /*logits*/ (i == (int)inp.size() - 1));
    }
    if (llama_decode(ctx, batch) != 0) {
        llama_batch_free(batch);
        llama_free(ctx);
        return env->NewStringUTF("ERROR: decode(prompt)");
    }

    // Sampling params (por defecto ajustados para móviles)
    SamplerParams sp{};
    sp.temperature    = jtemp;
    sp.top_k          = jtop_k;
    sp.top_p          = jtop_p;
    sp.repeat_penalty = jrepeat_penalty;
    sp.repeat_last_n  = jrepeat_last_n;

    std::mt19937 rng((uint32_t)jseed);

    std::string out;
    int n_cur = (int)inp.size();

    // Ventana de repetición = prompt + generados (capado a repeat_last_n)
    std::vector<llama_token> recent = inp;
    if ((int)recent.size() > sp.repeat_last_n)
        recent.erase(recent.begin(), recent.end() - sp.repeat_last_n);

    // Stop tokens: EOS + <|im_end|> si existe
    std::vector<llama_token> stop_tokens;
    stop_tokens.push_back(llama_vocab_eos(vocab));
    {
        std::vector<llama_token> tmp;
        if (tokenize_robust(vocab, "<|im_end|>", false, true, tmp) == 1) {
            stop_tokens.push_back(tmp[0]);
        }
    }

    for (int step = 0; step < max_tokens; ++step) {
        const float* logits = llama_get_logits(ctx);
        if (!logits) break;

        llama_token tok = sample_token(logits, n_vocab, recent, sp, rng);

        if (std::find(stop_tokens.begin(), stop_tokens.end(), tok) != stop_tokens.end()) break;

        append_token_piece(vocab, tok, out);
        recent.push_back(tok);
        if ((int)recent.size() > sp.repeat_last_n)
            recent.erase(recent.begin());

        // Siguiente paso
        llama_batch_free(batch);
        batch = llama_batch_init(1, 0, 1);
        batch_add_token(batch, tok, /*pos*/ n_cur, /*logits*/ true);
        if (llama_decode(ctx, batch) != 0) break;
        ++n_cur;
    }

    llama_batch_free(batch);
    llama_free(ctx);
    return env->NewStringUTF(out.c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_learnsynth_learnsynth_1offline_1llm_LlamaJNI_free(
        JNIEnv*, jclass) {
    if (g_model) { llama_model_free(g_model); g_model = nullptr; }
}

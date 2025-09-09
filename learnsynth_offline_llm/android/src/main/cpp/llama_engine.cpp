#include "llama_engine.h"
#include <atomic>
#include <vector>
#include <thread>
#include <mutex>

// llama.cpp headers
#include "llama.h"

namespace {
class LlamaEngineImpl : public LlamaEngine {
public:
  LlamaEngineImpl(const LlamaEngineConfig& cfg) : cfg_(cfg) {
    llama_backend_init(false);

    llama_model_params mp = llama_model_default_params();
    mp.vocab_only = false;
    model_ = llama_load_model_from_file(cfg_.model_path.c_str(), mp);
    if (!model_) return;

    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = cfg_.n_ctx;
    cp.n_threads = cfg_.n_threads;
    ctx_ = llama_new_context_with_model(model_, cp);
  }

  ~LlamaEngineImpl() override {
    if (ctx_) llama_free(ctx_);
    if (model_) llama_free_model(model_);
    llama_backend_free();
  }

  bool is_ready() const override { return ctx_ != nullptr; }

  void cancel() override { cancelled_.store(true); }

  bool generate(const std::string& prompt,
                std::function<void(const std::string&)> on_token) override {
    if (!ctx_) return false;
    cancelled_.store(false);

    std::vector<llama_token> inp;
    {
      inp.resize(prompt.size() + 32);
      int n = llama_tokenize(ctx_, prompt.c_str(), inp.data(), (int)inp.size(), true, false);
      if (n < 0) return false;
      inp.resize(n);
    }

    const int n_tokens = (int)inp.size();
    int n_eval = 0;
    while (n_eval < n_tokens) {
      if (cancelled_.load()) return true;
      int n_batch = 64;
      int n_eval_cur = std::min(n_batch, n_tokens - n_eval);
      if (llama_decode(ctx_, llama_batch_get_one(&inp[n_eval], n_eval_cur, 0, 0)) != 0) {
        return false;
      }
      n_eval += n_eval_cur;
    }

    int n_generated = 0;
    while (n_generated < cfg_.max_tokens) {
      if (cancelled_.load()) break;
      llama_token id = llama_token_eos(model_);
      {
        const float* logits = llama_get_logits(ctx_);
        const int n_vocab = llama_n_vocab(model_);
        int best = 0;
        float bestLogit = logits[0];
        for (int i = 1; i < n_vocab; ++i) {
          if (logits[i] > bestLogit) { bestLogit = logits[i]; best = i; }
        }
        id = best;
      }

      if (id == llama_token_eos(model_)) break;

      char buf[512];
      int n = llama_token_to_piece(model_, id, buf, sizeof(buf), 0, true);
      if (n > 0) on_token(std::string(buf, n));

      if (llama_decode(ctx_, llama_batch_get_one(&id, 1, 0, 0)) != 0) {
        return false;
      }
      ++n_generated;
    }
    return true;
  }

private:
  LlamaEngineConfig cfg_;
  llama_model* model_ = nullptr;
  llama_context* ctx_ = nullptr;
  std::atomic<bool> cancelled_{false};
};
} // namespace

std::unique_ptr<LlamaEngine> LlamaEngine::create(const LlamaEngineConfig& cfg) {
  auto eng = std::make_unique<LlamaEngineImpl>(cfg);
  if (!eng->is_ready()) return nullptr;
  return eng;
}

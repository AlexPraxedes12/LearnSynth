#include <jni.h>
#include <string>
#include <thread>
#include <atomic>
#include "llama_engine.h"

static JavaVM* g_vm = nullptr;
static jclass g_bridgeClass = nullptr;
static jmethodID g_onToken = nullptr;

extern "C" jint JNI_OnLoad(JavaVM* vm, void*) {
  g_vm = vm;
  return JNI_VERSION_1_6;
}

static std::unique_ptr<LlamaEngine> g_engine;
static std::thread g_worker;
static std::atomic<bool> g_running{false};

extern "C" JNIEXPORT jboolean JNICALL
Java_com_learnsynth_offline_1llm_LlamaBridge_nativeInit(JNIEnv* env, jclass,
                                                        jstring jModelPath, jint nCtx, jint nThreads) {
  const char* cpath = env->GetStringUTFChars(jModelPath, nullptr);
  LlamaEngineConfig cfg;
  cfg.model_path = cpath;
  cfg.n_ctx = nCtx;
  cfg.n_threads = nThreads;
  env->ReleaseStringUTFChars(jModelPath, cpath);

  g_engine = LlamaEngine::create(cfg);
  return g_engine ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT void JNICALL
Java_com_learnsynth_offline_1llm_LlamaBridge_nativeCancel(JNIEnv*, jclass) {
  if (g_engine) g_engine->cancel();
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_learnsynth_offline_1llm_LlamaBridge_nativeGenerate(JNIEnv* env, jclass,
                                                            jstring jPrompt, jint maxTokens, jfloat temp) {
  if (!g_engine) return JNI_FALSE;

  const char* cprompt = env->GetStringUTFChars(jPrompt, nullptr);
  std::string prompt(cprompt);
  env->ReleaseStringUTFChars(jPrompt, cprompt);

  auto onTok = [env](const std::string& s) {
    jclass cls = g_bridgeClass;
    if (!cls || !g_onToken) return;
    JNIEnv* e = env;
    bool didAttach = false;
    if (g_vm->GetEnv((void**)&e, JNI_VERSION_1_6) != JNI_OK) {
      g_vm->AttachCurrentThread(&e, nullptr);
      didAttach = true;
    }
    jstring js = e->NewStringUTF(s.c_str());
    e->CallStaticVoidMethod(cls, g_onToken, js);
    e->DeleteLocalRef(js);
    if (didAttach) g_vm->DetachCurrentThread();
  };

  g_running.store(true);
  bool ok = g_engine->generate(prompt, onTok);
  g_running.store(false);
  return ok ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT void JNICALL
Java_com_learnsynth_offline_1llm_LlamaBridge_nativeRegister(JNIEnv* env, jclass, jclass bridgeCls) {
  g_bridgeClass = (jclass)env->NewGlobalRef(bridgeCls);
  g_onToken = env->GetStaticMethodID(bridgeCls, "onTokenFromNative", "(Ljava/lang/String;)V");
}

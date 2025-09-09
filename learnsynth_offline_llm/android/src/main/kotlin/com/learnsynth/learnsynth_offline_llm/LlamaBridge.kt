package com.learnsynth.learnsynth_offline_llm

object LlamaBridge {
    init { System.loadLibrary("llama_runner") }

    @JvmStatic external fun nativeInit(modelPath: String, nCtx: Int, nThreads: Int): Boolean
    @JvmStatic external fun nativeGenerate(prompt: String, maxTokens: Int, temperature: Float): Boolean
    @JvmStatic external fun nativeCancel()
    @JvmStatic external fun nativeRegister(bridgeClass: Class<*>)

    @Volatile private var sink: ((String) -> Unit)? = null

    fun setSink(s: ((String) -> Unit)?) { sink = s }

    @JvmStatic fun onTokenFromNative(token: String) {
        sink?.invoke(token)
    }
}

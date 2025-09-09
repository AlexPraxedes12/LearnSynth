package com.learnsynth.learnsynth_offline_llm

object LlamaJNI {
    init {
        System.loadLibrary("learnsynth_offline_llm")
    }

    external fun isReady(): Boolean
    external fun loadModel(path: String): Boolean
    external fun generate(
        user: String,
        system: String?,
        maxTokens: Int,
        temp: Float,
        topP: Float,
        topK: Int,
        repeatPenalty: Float,
        repeatLastN: Int,
        seed: Int
    ): String
    external fun free()
}

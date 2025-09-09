package com.learnsynth.learnsynth_offline_llm

interface Runner {
    suspend fun load(modelPath: String)
    fun isReady(): Boolean
    fun generateStream(prompt: String, maxTokens: Int, temperature: Double, onToken: (String) -> Unit)
    fun cancel()
}

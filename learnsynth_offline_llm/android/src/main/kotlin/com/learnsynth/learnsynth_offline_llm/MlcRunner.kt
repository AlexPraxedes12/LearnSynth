package com.learnsynth.learnsynth_offline_llm

class MlcRunner : Runner {
    override suspend fun load(modelPath: String) {
        TODO("Implement MLC runner")
    }

    override fun isReady(): Boolean = false

    override fun generateStream(
        prompt: String,
        maxTokens: Int,
        temperature: Double,
        onToken: (String) -> Unit
    ) {
        // TODO
    }

    override fun cancel() {
        // TODO
    }
}

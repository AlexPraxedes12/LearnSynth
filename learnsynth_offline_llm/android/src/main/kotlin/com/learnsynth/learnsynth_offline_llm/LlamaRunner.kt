package com.learnsynth.learnsynth_offline_llm

class LlamaRunner : Runner {
    private var ready = false

    override suspend fun load(modelPath: String) {
        ready = LlamaBridge.nativeInit(modelPath, 2048, Runtime.getRuntime().availableProcessors() / 2)
        if (!ready) throw Exception("native init failed")
    }

    override fun isReady(): Boolean = ready

    override fun generateStream(prompt: String, maxTokens: Int, temperature: Double, onToken: (String) -> Unit) {
        LlamaBridge.setSink(onToken)
        val ok = LlamaBridge.nativeGenerate(prompt, maxTokens, temperature.toFloat())
        if (!ok) {
            // generation failed; caller may fallback
        }
        LlamaBridge.setSink(null)
    }

    override fun cancel() {
        LlamaBridge.nativeCancel()
    }
}

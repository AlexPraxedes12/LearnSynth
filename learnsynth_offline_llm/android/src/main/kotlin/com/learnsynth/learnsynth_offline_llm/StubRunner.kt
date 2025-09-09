package com.learnsynth.learnsynth_offline_llm

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class StubRunner : Runner {
    private var ready = false
    private var job: Job? = null
    private val scope = CoroutineScope(Dispatchers.Default)

    override suspend fun load(modelPath: String) {
        ready = true
    }

    override fun isReady(): Boolean = ready

    override fun generateStream(
        prompt: String,
        maxTokens: Int,
        temperature: Double,
        onToken: (String) -> Unit
    ) {
        job?.cancel()
        job = scope.launch {
            val text = "Android stub: $prompt"
            for (ch in text.toCharArray()) {
                onToken(ch.toString())
                delay(40)
            }
        }
    }

    override fun cancel() {
        job?.cancel()
    }
}

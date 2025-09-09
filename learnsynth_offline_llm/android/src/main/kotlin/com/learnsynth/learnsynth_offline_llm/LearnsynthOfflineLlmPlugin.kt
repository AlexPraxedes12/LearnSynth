package com.learnsynth.learnsynth_offline_llm

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class LearnsynthOfflineLlmPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "learnsynth_offline_llm"
        private const val CHANNEL = "learnsynth_offline_llm"
    }

    private lateinit var channel: MethodChannel
    private val main = Handler(Looper.getMainLooper())
    private val exec = Executors.newSingleThreadExecutor()

    @Volatile private var isGenerating = false
    @Volatile private var isLoaded = false

    private fun Number?.toIntOr(default: Int) = this?.toInt() ?: default
    private fun Number?.toDoubleOr(default: Double) = this?.toDouble() ?: default
    private fun Int.clamp(lo: Int, hi: Int) = maxOf(lo, minOf(hi, this))
    private fun Double.clamp(lo: Double, hi: Double) = maxOf(lo, minOf(hi, this))

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        exec.shutdown()
        try { LlamaJNI.free() } catch (_: Throwable) {}
        isLoaded = false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> {
                val s = when {
                    isGenerating -> "generating"
                    isLoaded -> "ok"
                    else -> "idle"
                }
                result.success(s)
            }

            "loadModel" -> {
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("ARG", "path is required", null)
                    return
                }
                exec.submit {
                    try {
                        val ok = LlamaJNI.loadModel(path)
                        isLoaded = ok
                        main.post { result.success(ok) }
                    } catch (t: Throwable) {
                        Log.e(TAG, "loadModel error", t)
                        isLoaded = false
                        main.post { result.error("LOAD", t.message, null) }
                    }
                }
            }

            "generate" -> {
                val prompt = call.argument<String>("prompt") ?: ""
                val systemPrompt = call.argument<String>("system")
                    ?: "Responde SIEMPRE en español neutro."
                val maxTokens = call.argument<Number>("maxTokens").toIntOr(64).clamp(1, 512)
                val temp = call.argument<Number>("temp").toDoubleOr(0.7).clamp(0.0, 2.0)
                val topK = call.argument<Number>("top_k").toIntOr(40).clamp(1, 1000)
                val topP = call.argument<Number>("top_p").toDoubleOr(0.95).clamp(0.0, 1.0)
                val repeatPenalty = call.argument<Number>("repeatPenalty").toDoubleOr(1.1).clamp(0.0, 2.0)
                val repeatLastN = call.argument<Number>("repeatLastN").toIntOr(64)
                val seed = call.argument<Number>("seed").toIntOr(1234)

                isGenerating = true
                exec.submit {
                    try {
                        Log.i(TAG, "generate start, effLen=${prompt.length}, maxTokens=$maxTokens")
                        val out = LlamaJNI.generate(
                            prompt,
                            systemPrompt,
                            maxTokens,
                            temp.toFloat(),
                            topP.toFloat(),
                            topK,
                            repeatPenalty.toFloat(),
                            repeatLastN,
                            seed
                        )
                        Log.i(TAG, "generate done, outLen=${out.length}")
                        main.post { result.success(out) }
                    } catch (t: Throwable) {
                        Log.e(TAG, "generate error", t)
                        main.post { result.error("GEN", t.message, null) }
                    } finally {
                        isGenerating = false
                    }
                }
            }

            "free" -> {
                exec.submit {
                    try {
                        LlamaJNI.free()
                        isLoaded = false
                        main.post { result.success(true) }
                    } catch (t: Throwable) {
                        Log.e(TAG, "free error", t)
                        main.post { result.error("FREE", t.message, null) }
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

}

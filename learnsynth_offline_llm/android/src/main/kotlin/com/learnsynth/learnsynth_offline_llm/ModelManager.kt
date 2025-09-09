package com.learnsynth.learnsynth_offline_llm

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.*
import java.net.HttpURLConnection
import java.net.URL
import java.security.DigestInputStream
import java.security.MessageDigest


data class ManifestFile(
    val name:String,
    val size:Long,
    val sha256:String,
    val url:String?,
    val asset:Boolean,
    val demo:Boolean
)
data class Manifest(val ctxLen:Int, val tokenizer:String, val files:List<ManifestFile>)

class ModelManager(private val context: Context, private val modelId: String) {
    private val TAG = "ModelManager"
    private val rootDir = File(context.filesDir, "models/$modelId")

    fun modelDir(): File = rootDir

    suspend fun ensureModel(manifest: Manifest, progress: (Map<String, Any?>) -> Unit) = withContext(Dispatchers.IO) {
        if (!rootDir.exists()) rootDir.mkdirs()
        for (f in manifest.files) {
            val out = File(rootDir, f.name)
            if (f.demo) {
                out.parentFile?.mkdirs()
                FileOutputStream(out).use { }
                progress(mapOf("stage" to "demo-generate", "file" to f.name, "received" to f.size, "total" to f.size, "percent" to 100))
            } else if (f.asset) {
                progress(mapOf("stage" to "copy-asset", "file" to f.name, "received" to 0, "total" to f.size, "percent" to 0))
                copyAsset("assets/models/$modelId/${f.name}", out)
            } else {
                if (!out.exists() || !verifySha256(out, f.sha256)) {
                    if (f.url.isNullOrBlank()) throw IOException("Missing URL for ${f.name}")
                    downloadTo(f.url!!, out, f.size) { rec, tot, pct ->
                        progress(mapOf("stage" to "downloading", "file" to f.name, "received" to rec, "total" to tot, "percent" to pct))
                    }
                }
            }
            progress(mapOf("stage" to "verifying", "file" to f.name, "received" to f.size, "total" to f.size, "percent" to 100))
            if (!verifySha256(out, f.sha256)) throw IOException("SHA256 mismatch: ${f.name}")
        }
        progress(mapOf("stage" to "done", "file" to "", "received" to 0, "total" to 0, "percent" to 100))
    }

    fun isReady(manifest: Manifest): Boolean {
        if (!rootDir.exists()) return false
        return try {
            manifest.files.all { f ->
                val out = File(rootDir, f.name)
                out.exists() && verifySha256(out, f.sha256)
            }
        } catch (e: Exception) { false }
    }

    private fun copyAsset(path: String, dst: File) {
        dst.parentFile?.mkdirs()
        context.assets.open(path).use { `in` ->
            FileOutputStream(dst).use { out ->
                `in`.copyTo(out)
            }
        }
    }

    private fun verifySha256(file: File, hex: String): Boolean {
        val md = MessageDigest.getInstance("SHA-256")
        DigestInputStream(FileInputStream(file), md).use { it.copyTo(OutputStream.nullOutputStream()) }
        val digest = md.digest().joinToString("") { "%02x".format(it) }
        val expected = hex.trim().lowercase()
        val actual = digest.trim().lowercase()
        return expected == actual
    }

    private fun downloadTo(urlStr: String, dst: File, total: Long, onProg: (rec: Int, tot: Int, pct: Int) -> Unit) {
        dst.parentFile?.mkdirs()
        val tmp = File(dst.absolutePath + ".part")
        var conn: HttpURLConnection? = null
        var received = 0L
        try {
            conn = URL(urlStr).openConnection() as HttpURLConnection
            conn.connectTimeout = 15000; conn.readTimeout = 300000
            conn.inputStream.use { input ->
                FileOutputStream(tmp).use { out ->
                    val buf = ByteArray(8192)
                    while (true) {
                        val n = input.read(buf)
                        if (n <= 0) break
                        out.write(buf, 0, n)
                        received += n
                        val pct = if (total > 0) ((received * 100) / total).toInt() else 0
                        onProg(received.toInt(), total.toInt(), pct)
                    }
                }
            }
            if (dst.exists()) dst.delete()
            tmp.renameTo(dst)
        } finally {
            conn?.disconnect()
            if (tmp.exists() && (!dst.exists() || tmp.length() != dst.length())) tmp.delete()
        }
    }
}

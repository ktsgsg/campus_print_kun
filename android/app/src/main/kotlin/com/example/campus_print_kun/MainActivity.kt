package com.example.campus_print_kun

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.campusPrintKun/sharing"
    }

    private var channel: MethodChannel? = null
    private var pendingPdfPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingPdfPath = extractPdfPath(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialSharedPdf" -> {
                        result.success(pendingPdfPath)
                        pendingPdfPath = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val path = extractPdfPath(intent) ?: return
        channel?.invokeMethod("sharedPdfReceived", path)
    }

    private fun extractPdfPath(intent: Intent?): String? {
        if (intent == null) return null
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> getSendUri(intent)
            else -> null
        }
        return uri?.let { copyUriToCache(it) }
    }

    @Suppress("DEPRECATION")
    private fun getSendUri(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun copyUriToCache(uri: Uri): String? {
        return try {
            val fileName = queryDisplayName(uri)
                ?: uri.lastPathSegment
                    ?.substringAfterLast('/')
                    ?.takeIf { it.isNotBlank() && it.endsWith(".pdf", ignoreCase = true) }
                ?: "shared.pdf"
            val dest = File(cacheDir, fileName)
            contentResolver.openInputStream(uri)?.use { input ->
                dest.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            dest.absolutePath
        } catch (e: IOException) {
            null
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme != "content") return null
        return contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0) cursor.getString(idx) else null
                } else null
            }
            ?.takeIf { it.isNotBlank() }
    }
}

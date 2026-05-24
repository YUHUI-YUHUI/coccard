package com.coccard.app

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val backupChannel = "coccard/backup"
    private val pickJsonRequestCode = 4101
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, backupChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareText" -> {
                        val title = call.argument<String>("title") ?: "分享"
                        val text = call.argument<String>("text") ?: ""
                        if (text.isBlank()) {
                            result.error("EMPTY_TEXT", "分享内容为空", null)
                            return@setMethodCallHandler
                        }

                        val sendIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                            putExtra(Intent.EXTRA_TITLE, title)
                        }
                        startActivity(Intent.createChooser(sendIntent, title))
                        result.success(null)
                    }
                    "pickJsonText" -> {
                        if (pendingPickResult != null) {
                            result.error("PICKER_BUSY", "文件选择器正在打开", null)
                            return@setMethodCallHandler
                        }

                        val pickIntent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(
                                Intent.EXTRA_MIME_TYPES,
                                arrayOf("application/json", "text/plain")
                            )
                        }
                        pendingPickResult = result
                        startActivityForResult(pickIntent, pickJsonRequestCode)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != pickJsonRequestCode) return

        val result = pendingPickResult ?: return
        pendingPickResult = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return
        }

        try {
            val text = contentResolver.openInputStream(uri)?.bufferedReader().use {
                it?.readText()
            }
            result.success(text)
        } catch (e: Exception) {
            result.error("READ_FAILED", e.message, null)
        }
    }
}

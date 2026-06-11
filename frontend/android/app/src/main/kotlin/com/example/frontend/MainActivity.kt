package com.example.frontend

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "monmon/downloads"
    private val storagePermissionRequestCode = 4921
    private var pendingDownload: PendingDownload? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val bytes = call.argument<ByteArray>("bytes")
                val fileName = call.argument<String>("fileName")
                val mimeType = call.argument<String>("mimeType")

                if (bytes == null || fileName.isNullOrBlank() || mimeType.isNullOrBlank()) {
                    result.error("INVALID_ARGS", "Missing file data, name, or MIME type.", null)
                    return@setMethodCallHandler
                }

                try {
                    saveToDownloadsWithPermission(bytes, fileName, mimeType, result)
                } catch (error: Exception) {
                    result.error("SAVE_FAILED", error.message, null)
                }
            }
    }

    private fun saveToDownloadsWithPermission(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
        result: MethodChannel.Result
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q || hasLegacyStoragePermission()) {
            result.success(saveToDownloads(bytes, fileName, mimeType))
            return
        }

        if (pendingDownload != null) {
            result.error("SAVE_BUSY", "Another download is waiting for permission.", null)
            return
        }

        pendingDownload = PendingDownload(bytes, fileName, mimeType, result)
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
            storagePermissionRequestCode
        )
    }

    private fun hasLegacyStoragePermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != storagePermissionRequestCode) {
            return
        }

        val download = pendingDownload ?: return
        pendingDownload = null

        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            try {
                download.result.success(
                    saveToDownloads(download.bytes, download.fileName, download.mimeType)
                )
            } catch (error: Exception) {
                download.result.error("SAVE_FAILED", error.message, null)
            }
        } else {
            download.result.error(
                "PERMISSION_DENIED",
                "Storage permission is required to save files to Download on this Android version.",
                null
            )
        }
    }

    private fun saveToDownloads(bytes: ByteArray, fileName: String, mimeType: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Unable to create download entry.")

            resolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
            } ?: throw IllegalStateException("Unable to open download output stream.")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            uri.toString()
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }

            val file = File(downloadsDir, fileName)
            FileOutputStream(file).use { output ->
                output.write(bytes)
            }

            file.absolutePath
        }
    }

    private data class PendingDownload(
        val bytes: ByteArray,
        val fileName: String,
        val mimeType: String,
        val result: MethodChannel.Result
    )
}

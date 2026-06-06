package com.example.opalmer_education

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "classpluse/downloads"
    private val appFolderName = "ClassPluse"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel).setMethodCallHandler {
            call,
            result ->
            if (call.method != "saveToClassPluse") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val bytes = call.argument<ByteArray>("bytes")
            val fileName = call.argument<String>("fileName") ?: "lesson-document"
            val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
            val isImage = call.argument<Boolean>("isImage") ?: false

            if (bytes == null || bytes.isEmpty()) {
                result.error("EMPTY_FILE", "Downloaded file is empty.", null)
                return@setMethodCallHandler
            }

            try {
                val savedLocation = saveToClassPluse(bytes, fileName, mimeType, isImage)
                result.success(savedLocation)
            } catch (error: Exception) {
                result.error("SAVE_FAILED", error.localizedMessage, null)
            }
        }
    }

    private fun saveToClassPluse(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
        isImage: Boolean
    ): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveWithMediaStore(bytes, fileName, mimeType, isImage)
        } else {
            saveLegacy(bytes, fileName, isImage)
        }
    }

    private fun saveWithMediaStore(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
        isImage: Boolean
    ): String {
        val collection: Uri
        val relativePath: String

        if (isImage) {
            collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            relativePath = "${Environment.DIRECTORY_PICTURES}/$appFolderName"
        } else {
            collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
            relativePath = "${Environment.DIRECTORY_DOWNLOADS}/$appFolderName"
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val resolver = applicationContext.contentResolver
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("Could not create file in $relativePath.")

        resolver.openOutputStream(uri)?.use { output ->
            output.write(bytes)
        } ?: throw IllegalStateException("Could not write file.")

        values.clear()
        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, values, null, null)

        return if (isImage) {
            "Saved to Gallery > $appFolderName"
        } else {
            "Saved to Downloads/$appFolderName"
        }
    }

    private fun saveLegacy(bytes: ByteArray, fileName: String, isImage: Boolean): String {
        val baseDirectory = if (isImage) {
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
        } else {
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        }
        val targetDirectory = File(baseDirectory, appFolderName)
        if (!targetDirectory.exists()) targetDirectory.mkdirs()

        val targetFile = File(targetDirectory, fileName)
        FileOutputStream(targetFile).use { output ->
            output.write(bytes)
        }

        MediaScannerConnection.scanFile(
            applicationContext,
            arrayOf(targetFile.absolutePath),
            null,
            null
        )

        return "Saved to ${targetFile.absolutePath}"
    }
}

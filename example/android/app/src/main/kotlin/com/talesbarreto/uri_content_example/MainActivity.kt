package com.talesbarreto.uri_content_example

import android.content.ContentUris
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val channel = "com.talesbarreto.uri_content/example"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->
            if (call.method == "getPhotosUrisFromMediaStore") {
                val uris = getPhotosUrisFromMediaStore()
                result.success(uris.map { it.toString() })
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getPhotosUrisFromMediaStore(): MutableList<Uri> {
        val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.SIZE
        )
        val selection = "${MediaStore.Images.Media.SIZE} >= ?"
        val selectionArgs = arrayOf("100000")
        val sortOrder = "${MediaStore.Images.Media.DISPLAY_NAME} ASC"
        val cursor = contentResolver.query(
            uri,
            projection,
            selection,
            selectionArgs,
            sortOrder
        )
        val columnIndexId = cursor?.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
        val columnIndexDisplayName =
            cursor?.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
        val columnIndexSize = cursor?.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE)
        val uris = mutableListOf<Uri>()
        cursor?.use {
            while (it.moveToNext()) {
                val id = columnIndexId?.let { it1 -> it.getLong(it1) }
                val displayName = columnIndexDisplayName?.let { it1 -> it.getString(it1) }
                val size = columnIndexSize?.let { it1 -> it.getLong(it1) }
                val contentUri = ContentUris.withAppendedId(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    id ?: 0
                )
                uris.add(contentUri)
            }
        }
        cursor?.close()
        return uris
    }
}

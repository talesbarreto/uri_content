package com.talesbarreto.uri_content

import android.content.ContentResolver
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedInputStream
import java.lang.Exception
import kotlin.coroutines.coroutineContext

/** UriContentPlugin */
class UriContentPlugin : FlutterPlugin, MethodCallHandler, Api.UriContentNativeApi {
    private lateinit var channel: MethodChannel
    private var contentResolver: ContentResolver? = null
    private var flutterApi: Api.UriContentFlutterApi? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "uri_content")
        channel.setMethodCallHandler(this)
        contentResolver = flutterPluginBinding.applicationContext.contentResolver
        flutterApi = Api.UriContentFlutterApi(flutterPluginBinding.binaryMessenger)
        Api.UriContentNativeApi.setup(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun getContentFromUri(url: String, requestId: Long, bufferSize: Long) {
        val contentResolver = this.contentResolver ?: throw Exception("ContentResolver is null")
        val flutterApi = this.flutterApi ?: throw Exception("Flutter API is null")
        val uri = Uri.parse(url)
        val stream = contentResolver.openInputStream(uri)
        val bufferedInputStream = BufferedInputStream(stream, bufferSize.toInt())

        if (stream == null) {
            flutterApi.onDataReceived(requestId, null, "could not open data stream") { }
            return
        }
        try {
            var bytesRead: Int
            val buffer = ByteArray(bufferSize.toInt())
            while (bufferedInputStream.read(buffer).also { bytesRead = it } != -1) {
                val data = buffer.sliceArray(0 until bytesRead)
                flutterApi.onDataReceived(requestId, data, null) { }
            }
            // dataArg null means we reached EOF and stream can be closed
            flutterApi.onDataReceived(requestId, null, null) { }
        } catch (exception: Exception) {
            flutterApi.onDataReceived(requestId, null, exception.toString()) { }
        } finally {
            bufferedInputStream.close()
            stream.close()
        }
    }
}

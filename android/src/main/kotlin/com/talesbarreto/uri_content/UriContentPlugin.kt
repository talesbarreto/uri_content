package com.talesbarreto.uri_content

import android.content.ContentResolver
import android.net.Uri
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.InputStream
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.coroutines.CoroutineContext

/** UriContentPlugin */
class UriContentPlugin : FlutterPlugin, MethodCallHandler, Api.UriContentNativeApi,
    CoroutineScope {

    override val coroutineContext: CoroutineContext = Job() + Dispatchers.IO
    private lateinit var channel: MethodChannel
    private var contentResolver: ContentResolver? = null
    private var flutterApi: Api.UriContentFlutterApi? = null
    private val activeRequests = CopyOnWriteArrayList<Long>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "uri_content")
        channel.setMethodCallHandler(this)
        contentResolver = flutterPluginBinding.applicationContext.contentResolver
        flutterApi = Api.UriContentFlutterApi(flutterPluginBinding.binaryMessenger)
        Api.UriContentNativeApi.setup(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun getContentFromUri(url: String, requestId: Long, bufferSize: Long) {
        val flutterApi = flutterApi ?: return
        val contentResolver = contentResolver

        if (contentResolver == null) {
            flutterApi.onDataReceived(requestId, null, "ContentResolver is null") { }
            return
        }
        activeRequests.add(requestId)

        launch {
            var inputStream: InputStream? = null
            var bufferedInputStream: BufferedInputStream? = null
            try {
                val uri = Uri.parse(url)

                inputStream = contentResolver.openInputStream(uri)

                bufferedInputStream = BufferedInputStream(inputStream, bufferSize.toInt())

                var bytesRead: Int
                val buffer = ByteArray(bufferSize.toInt())
                while (bufferedInputStream.read(buffer).also { bytesRead = it } != -1) {
                    if (requestId !in activeRequests) {
                        withContext(Dispatchers.Main) {
                            flutterApi.onDataReceived(requestId, null, "request cancelled") { }
                        }
                        return@launch
                    }
                    val data = buffer.sliceArray(0 until bytesRead)
                    withContext(Dispatchers.Main) {
                        flutterApi.onDataReceived(requestId, data, null) { }
                    }
                }
                // dataArg null means we reached EOF and stream can be closed
                withContext(Dispatchers.Main) {
                    flutterApi.onDataReceived(requestId, null, null) { }
                }

            } catch (exception: Exception) {
                withContext(Dispatchers.Main) {
                    flutterApi.onDataReceived(requestId, null, exception.toString()) { }
                }
            } finally {
                activeRequests.remove(requestId)
                inputStream?.close()
                bufferedInputStream?.close()
            }
        }
    }

    override fun onRequestCancelled(requestId: Long) {
        activeRequests.remove(requestId)
    }

    override fun doesFileExist(url: String, result: Api.Result<Boolean>) {
        launch {
            val contentResolver = contentResolver

            if (contentResolver == null) {
                withContext(Dispatchers.Main) {
                    result.error(Exception("ContentResolver is null"))
                }
                return@launch
            }
            var stream: InputStream? = null
            try {
                val uri = Uri.parse(url)
                stream = contentResolver.openInputStream(uri)
                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.success(false)
                }
            } finally {
                stream?.close()
            }
        }
    }
}

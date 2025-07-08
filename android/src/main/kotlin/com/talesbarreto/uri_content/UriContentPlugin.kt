package com.talesbarreto.uri_content

import android.content.ContentResolver
import android.util.Log
import androidx.core.net.toUri
import com.talesbarreto.uri_content.extension.tryUnlock
import com.talesbarreto.uri_content.model.UriContentRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.InputStream
import kotlin.coroutines.CoroutineContext
import io.flutter.plugin.common.MethodChannel.Result as MethodChannelResult

/** UriContentPlugin */
class UriContentPlugin : FlutterPlugin, MethodCallHandler, UriContentPlatformApi,
    CoroutineScope {

    override val coroutineContext: CoroutineContext = Job() + Dispatchers.Main
    private lateinit var channel: MethodChannel
    private var contentResolver: ContentResolver? = null
    private val activeRequests = HashMap<Long, UriContentRequest>()
    private val activeRequestsLock = Mutex()

    private val filesBeingReadCount = MutableStateFlow(0)

    private suspend fun getRequest(requestId: Long): UriContentRequest? {
        return activeRequestsLock.withLock {
            activeRequests[requestId]
        }
    }

    private suspend fun setRequest(requestId: Long, request: UriContentRequest) {
        activeRequestsLock.withLock {
            activeRequests[requestId] = request
        }
    }

    private suspend fun deleteRequest(requestId: Long): UriContentRequest? {
        return activeRequestsLock.withLock {
            activeRequests.remove(requestId)
        }
    }

    private suspend fun updateRequest(
        requestId: Long,
        update: UriContentRequest.() -> UriContentRequest
    ) {
        activeRequestsLock.withLock {
            activeRequests[requestId]?.let {
                activeRequests[requestId] = update(it)
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "uri_content")
        channel.setMethodCallHandler(this)
        contentResolver = flutterPluginBinding.applicationContext.contentResolver
        UriContentPlatformApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannelResult) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private suspend fun requestContent(url: String, requestId: Long, bufferSize: Long) {
        val contentResolver = contentResolver ?: throw Exception("ContentResolver is null")
        val readingDataLock = getRequest(requestId)?.readingDataLock ?: return
        var inputStream: InputStream? = null
        var bufferedInputStream: BufferedInputStream? = null
        try {
            filesBeingReadCount.update { it + 1 }
            val uri = url.toUri()

            inputStream = contentResolver.openInputStream(uri)

            bufferedInputStream = BufferedInputStream(inputStream, bufferSize.toInt())

            val buffer = ByteArray(bufferSize.toInt())

            val requestLock = getRequest(requestId)?.requestLock ?: return
            do {
                // Starts locked by default, it is unlocked by requestNextChunk when dart side
                // requests the next (or first) data chunk
                requestLock.lock()

                val bytesRead: Int? = withContext(Dispatchers.IO) {
                    try {
                        bufferedInputStream.read(buffer)
                    } catch (_: Exception) {
                        null
                    }
                }

                if (bytesRead == null) {
                    updateRequest(requestId) {
                        copy(readChunk = null, error = "Error reading data")
                    }
                    readingDataLock.tryUnlock()
                    return
                }

                if (bytesRead == -1) {
                    updateRequest(requestId) {
                        copy(readChunk = null, done = true)
                    }
                    readingDataLock.tryUnlock()
                    return
                }

                val data = buffer.sliceArray(0 until bytesRead)
                updateRequest(requestId) {
                    copy(readChunk = data)
                }

                readingDataLock.tryUnlock()
            } while (true)
        } catch (exception: Exception) {
            updateRequest(requestId) {
                copy(readChunk = null, error = exception.toString())
            }
        } finally {
            filesBeingReadCount.update { it - 1 }
            withContext(Dispatchers.IO) {
                inputStream?.close()
                bufferedInputStream?.close()
            }
        }
    }

    override fun startRequest(
        url: String,
        requestId: Long,
        bufferSize: Long,
        callback: (Result<Unit>) -> Unit
    ) {
        launch {
            try {
                if (!activeRequests.contains(requestId)) {
                    setRequest(requestId, UriContentRequest(bufferSize))
                    callback(Result.success(Unit))
                    waitForMemoryToBeAvailable(bufferSize)
                    requestContent(url, requestId, bufferSize)
                } else {
                    callback(Result.failure(Exception("Can't start request with id $requestId because it already exists")))
                }
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    private suspend fun waitForMemoryToBeAvailable(bufferSize: Long) {
        while (Runtime.getRuntime().freeMemory() < 4 * bufferSize) {
            val filesBeingRead = filesBeingReadCount.value

            // Wait for a change in active requests
            val currentFilesBeingRead =
                filesBeingReadCount.filter { it ->
                    it != filesBeingRead || it < 1
                }.first()

            if (currentFilesBeingRead <= 1) {
                break
            }
        }
    }

    override fun requestNextChunk(
        requestId: Long,
        callback: (Result<UriContentChunkResult>) -> Unit
    ) {
        launch(Dispatchers.Main) {
            val result: Result<UriContentChunkResult>
            val request = getRequest(requestId)
            if (request == null) {
                callback(Result.failure(Exception("Request not found")))
                return@launch
            }

            request.readingDataLock.lock() // To be unlocked by [getRequest], after it is finished
            request.requestLock.tryUnlock() // Release [getRequest] to read next chunk
            request.readingDataLock.withLock { // Wait for the next chunk to be available
                val requestResult = getRequest(requestId)
                if (requestResult == null) {
                    result = Result.failure(Exception("Request not found"))
                } else if (requestResult.done) {
                    result = Result.success(UriContentChunkResult(null, true))
                    cancelRequest(requestId)
                } else if (requestResult.error != null) {
                    result = Result.success(
                        UriContentChunkResult(
                            null,
                            false,
                            error = requestResult.error
                        )
                    )
                    cancelRequest(requestId)
                } else {
                    val data = requestResult.readChunk
                    result = Result.success(UriContentChunkResult(data, false))
                }
            }
            callback(result)
        }
    }

    override fun cancelRequest(requestId: Long) {
        launch {
            val request = deleteRequest(requestId)
            request?.requestLock?.tryUnlock()
            request?.readingDataLock?.tryUnlock()
        }
    }

    override fun getContentLength(url: String, callback: (Result<Long?>) -> Unit) {
        val contentResolver = contentResolver
        if (contentResolver == null) {
            callback(Result.failure(Exception("ContentResolver is null")))
            return
        }
        launch {
            try {
                val uri = url.toUri()
                val parcelFileDescriptor = contentResolver.openFileDescriptor(uri, "r")
                val contentSize = parcelFileDescriptor?.statSize
                parcelFileDescriptor?.close()
                withContext(Dispatchers.Main) {
                    callback(Result.success(contentSize))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun exists(url: String, callback: (Result<Boolean>) -> Unit) {
        launch {
            val contentResolver = contentResolver

            if (contentResolver == null) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(Exception("ContentResolver is null")))
                }
                return@launch
            }
            var stream: InputStream? = null
            try {
                val uri = url.toUri()
                stream = contentResolver.openInputStream(uri)
                withContext(Dispatchers.Main) {
                    callback(Result.success(true))
                }
            } catch (_: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.success(false))
                }
            } finally {
                withContext(Dispatchers.IO) {
                    stream?.close()
                }
            }
        }
    }
}

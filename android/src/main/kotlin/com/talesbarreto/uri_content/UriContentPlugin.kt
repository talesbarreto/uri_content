package com.talesbarreto.uri_content

import android.content.ContentResolver
import androidx.core.net.toUri
import com.talesbarreto.uri_content.extension.tryUnlock
import com.talesbarreto.uri_content.model.UriContentActiveRequests
import com.talesbarreto.uri_content.model.UriContentRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
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

    // A map to keep track of active requests and their metadata.
    private val activeRequests = UriContentActiveRequests()

    // A counter to keep track of how many files are currently being read.
    private val concurrentReadOperationCounterFlow = MutableStateFlow(0)

    private val concurrentReadOperationCounter
        get() = concurrentReadOperationCounterFlow.value

    private val freeMemory
        get() = Runtime.getRuntime().freeMemory()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "uri_content")
        channel.setMethodCallHandler(this)
        contentResolver = flutterPluginBinding.applicationContext.contentResolver
        UriContentPlatformApi.setUp(
            binaryMessenger = flutterPluginBinding.binaryMessenger,
            api = this
        )
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannelResult) {
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    /// See api_interface/uri_content_native_api.dart documentation to understand the API flow.
    override fun registerRequest(
        url: String,
        requestId: Long,
        bufferSize: Long,
        callback: (Result<Unit>) -> Unit
    ) {
        launch {
            try {
                if (!activeRequests.contains(requestId)) {
                    activeRequests.registerRequest(requestId, UriContentRequest(bufferSize))
                    callback(Result.success(Unit))
                    waitForEnoughMemoryToBeAvailable(bufferSize)
                    readFileChunks(url, requestId, bufferSize)
                } else {
                    callback(Result.failure(Exception("Can't start request with id $requestId because it already exists")))
                }
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }


    override fun requestNextChunk(
        requestId: Long,
        callback: (Result<UriContentChunkResult>) -> Unit
    ) {
        launch {
            val result: Result<UriContentChunkResult>
            val request = activeRequests.getRequest(requestId)
            if (request == null) {
                callback(Result.failure(Exception("Request not found")))
                return@launch
            }

            // Checking errors on inputStream opening
            if (request.error != null) {
                result = Result.success(
                    UriContentChunkResult(
                        null,
                        false,
                        error = request.error
                    )
                )
                cancelRequest(requestId)
                callback(result)
                return@launch
            }

            request.chunkResultLock.lock() // To be unlocked by [readFileChunks], after it is finished
            request.nextChunkLock.tryUnlock() // Release [readFileChunks] to read next chunk
            request.chunkResultLock.withLock { // Wait for the next chunk to be available
                val requestResult = activeRequests.getRequest(requestId)
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
                    result = Result.success(
                        UriContentChunkResult(
                            chunk = activeRequests.removeReadChunk(requestId),
                            done = false,
                        )
                    )
                }
            }
            callback(result)
        }
    }

    private suspend fun readFileChunks(url: String, requestId: Long, bufferSize: Long) {
        val contentResolver = contentResolver ?: throw Exception("ContentResolver is null")
        val chunkResultLock = activeRequests.getChunkResultLock(requestId) ?: return
        var inputStream: InputStream? = null
        var bufferedInputStream: BufferedInputStream? = null

        try {
            concurrentReadOperationCounterFlow.update { it + 1 }
            val uri = url.toUri()

            inputStream = contentResolver.openInputStream(uri)

            bufferedInputStream = BufferedInputStream(inputStream, bufferSize.toInt())

            val buffer = ByteArray(bufferSize.toInt())

            val nextChunkLock = activeRequests.getNextChunkLock(requestId) ?: return

            while (true) {
                // Starts locked by default, it is unlocked by requestNextChunk when dart side
                // requests the next (or first) data chunk
                nextChunkLock.lock()

                if (!activeRequests.contains(requestId)) {
                    chunkResultLock.tryUnlock()
                    return
                }

                var exception: Exception? = null

                val bytesRead: Int? = withContext(Dispatchers.IO) {
                    try {
                        bufferedInputStream.read(buffer)
                    } catch (e: Exception) {
                        exception = e
                        null
                    }
                }

                when (bytesRead) {
                    null -> activeRequests.updateRequest(requestId) {
                        copy(readChunk = null, error = exception?.toString())
                    }

                    -1 -> activeRequests.updateRequest(requestId) {
                        copy(readChunk = null, done = true)
                    }

                    else -> {
                        val data = buffer.sliceArray(0 until bytesRead)
                        activeRequests.updateRequest(requestId) {
                            copy(readChunk = data)
                        }
                    }
                }

                chunkResultLock.tryUnlock()

            }
        } catch (exception: Exception) {
            activeRequests.updateRequest(requestId) {
                copy(readChunk = null, error = exception.toString())
            }
        } finally {
            concurrentReadOperationCounterFlow.update { it - 1 }
            withContext(Dispatchers.IO) {
                inputStream?.close()
                bufferedInputStream?.close()
            }
        }
    }

    private suspend fun waitForEnoughMemoryToBeAvailable(bufferSize: Long) {
        while (concurrentReadOperationCounter > 1 && freeMemory < 4 * bufferSize) {
            val oldCount = concurrentReadOperationCounter

            // Wait for a change in active requests
            concurrentReadOperationCounterFlow.filter { it -> it != oldCount || it < 1 }.first()
        }
    }

    override fun cancelRequest(requestId: Long) {
        launch {
            val request = activeRequests.deleteRequest(requestId)
            request?.nextChunkLock?.tryUnlock()
            request?.chunkResultLock?.tryUnlock()
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

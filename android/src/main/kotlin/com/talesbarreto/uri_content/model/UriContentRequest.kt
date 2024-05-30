package com.talesbarreto.uri_content.model

import kotlinx.coroutines.sync.Mutex

data class UriContentRequest(
        val bufferSize: Long,
        val done: Boolean = false,
        val requestLock: Mutex = Mutex(locked = true),
        val readingDataLock: Mutex = Mutex(locked = false),
        val readChunk: ByteArray? = null,
        val error: String? = null,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as UriContentRequest

        if (bufferSize != other.bufferSize) return false
        if (done != other.done) return false
        if (requestLock != other.requestLock) return false
        if (readingDataLock != other.readingDataLock) return false
        if (readChunk != null) {
            if (other.readChunk == null) return false
            if (!readChunk.contentEquals(other.readChunk)) return false
        } else if (other.readChunk != null) return false
        if (error != other.error) return false

        return true
    }

    override fun hashCode(): Int {
        var result = bufferSize.hashCode()
        result = 31 * result + done.hashCode()
        result = 31 * result + requestLock.hashCode()
        result = 31 * result + readingDataLock.hashCode()
        result = 31 * result + (readChunk?.contentHashCode() ?: 0)
        result = 31 * result + (error?.hashCode() ?: 0)
        return result
    }

}

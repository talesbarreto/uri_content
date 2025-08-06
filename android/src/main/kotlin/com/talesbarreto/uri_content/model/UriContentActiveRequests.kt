package com.talesbarreto.uri_content.model

import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

class UriContentActiveRequests {

    private val activeRequests = HashMap<Long, UriContentRequest>()
    private val activeRequestsLock = Mutex()


    fun contains(requestId: Long): Boolean {
        return activeRequests.containsKey(requestId)
    }

    suspend fun getRequest(requestId: Long): UriContentRequest? {
        return activeRequestsLock.withLock {
            activeRequests[requestId]
        }
    }

    suspend fun registerRequest(requestId: Long, request: UriContentRequest) {
        activeRequestsLock.withLock {
            activeRequests[requestId] = request
        }
    }

    suspend fun deleteRequest(requestId: Long): UriContentRequest? {
        return activeRequestsLock.withLock {
            activeRequests.remove(requestId)
        }
    }

    suspend fun updateRequest(
        requestId: Long,
        update: UriContentRequest.() -> UriContentRequest
    ) {
        activeRequestsLock.withLock {
            activeRequests[requestId]?.let {
                activeRequests[requestId] = update(it)
            }
        }
    }

    fun getReadingDataLock(requestId: Long): Mutex? {
        return activeRequests[requestId]?.readingDataLock
    }

    fun getRequestDataLock(requestId: Long): Mutex? {
        return activeRequests[requestId]?.requestLock
    }
}
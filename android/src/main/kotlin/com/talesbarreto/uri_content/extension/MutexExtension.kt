package com.talesbarreto.uri_content.extension

import kotlinx.coroutines.sync.Mutex

fun Mutex.tryUnlock() {
    try {
        unlock()
    } catch (_: Exception) {
    }
}

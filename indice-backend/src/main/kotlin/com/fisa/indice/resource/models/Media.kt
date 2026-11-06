package com.fisa.indice.resource.models

import java.net.URI

data class Media(val url: String) {
    val type: MediaType = typeOf(url)

    companion object {
        private val TYPES_BY_EXTENSION = mapOf(
            "jpg" to MediaType.IMAGE,
            "jpeg" to MediaType.IMAGE,
            "png" to MediaType.IMAGE,
            "webp" to MediaType.IMAGE,
            "gif" to MediaType.IMAGE,
            "mp4" to MediaType.VIDEO,
            "mov" to MediaType.VIDEO,
            "webm" to MediaType.VIDEO,
            "m3u8" to MediaType.VIDEO,
        )

        private fun typeOf(url: String): MediaType {
            require(url.isNotBlank()) { "A media must have a URL" }
            val path = URI.create(url.trim()).path.orEmpty()
            val extension = path.substringAfterLast('/').substringAfterLast('.', missingDelimiterValue = "").lowercase()
            return requireNotNull(TYPES_BY_EXTENSION[extension]) { "Unsupported media extension in $url" }
        }
    }
}

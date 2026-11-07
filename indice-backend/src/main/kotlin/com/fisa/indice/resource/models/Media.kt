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

        private val YOUTUBE_HOSTS = setOf("youtube.com", "www.youtube.com")
        private const val YOUTUBE_VIDEO_PATH = "/watch"

        private fun typeOf(url: String): MediaType {
            require(url.isNotBlank()) { "A media must have a URL" }
            val uri = URI.create(url.trim())
            val path = uri.path.orEmpty()
            if (uri.host?.lowercase() in YOUTUBE_HOSTS && path == YOUTUBE_VIDEO_PATH) return MediaType.VIDEO
            val extension = path.substringAfterLast('/').substringAfterLast('.', missingDelimiterValue = "").lowercase()
            return requireNotNull(TYPES_BY_EXTENSION[extension]) { "Unsupported media extension in $url" }
        }
    }
}

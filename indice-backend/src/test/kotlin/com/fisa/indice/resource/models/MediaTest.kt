package com.fisa.indice.resource.models

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.ValueSource
import kotlin.test.assertEquals

class MediaTest {

    @ParameterizedTest
    @ValueSource(strings = ["jpg", "jpeg", "png", "webp", "gif"])
    fun `should be an image when the url has an image extension`(extension: String) {
        assertEquals(MediaType.IMAGE, Media("https://example.com/media/cover.$extension").type)
    }

    @ParameterizedTest
    @ValueSource(strings = ["mp4", "mov", "webm", "m3u8"])
    fun `should be a video when the url has a video extension`(extension: String) {
        assertEquals(MediaType.VIDEO, Media("https://example.com/media/lesson.$extension").type)
    }

    @ParameterizedTest
    @ValueSource(strings = ["https://www.youtube.com/watch?v=lA6b8tckrQQ", "https://youtube.com/watch?v=lA6b8tckrQQ"])
    fun `should be a video when the url is a youtube video page`(url: String) {
        assertEquals(MediaType.VIDEO, Media(url).type)
    }

    @Test
    fun `should reject a youtube page that is not a video`() {
        assertThrows<IllegalArgumentException> { Media("https://www.youtube.com/user/lafinancepourtous") }
    }

    @Test
    fun `should ignore the case of the extension`() {
        assertEquals(MediaType.VIDEO, Media("https://example.com/lesson.MP4").type)
    }

    @Test
    fun `should ignore query parameters and fragment`() {
        assertEquals(MediaType.IMAGE, Media("https://example.com/cover.png?width=300#top").type)
    }

    @Test
    fun `should reject a blank url`() {
        assertThrows<IllegalArgumentException> { Media(" ") }
    }

    @Test
    fun `should reject an unknown extension`() {
        assertThrows<IllegalArgumentException> { Media("https://example.com/document.pdf") }
    }

    @Test
    fun `should reject a url without extension`() {
        assertThrows<IllegalArgumentException> { Media("https://example.com/videos/lesson") }
    }

    @Test
    fun `should not take a dot of the host name for an extension`() {
        assertThrows<IllegalArgumentException> { Media("https://example.mp4") }
    }
}

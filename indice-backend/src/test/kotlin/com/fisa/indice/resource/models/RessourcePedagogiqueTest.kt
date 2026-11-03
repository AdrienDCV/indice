package com.fisa.indice.resource.models

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertDoesNotThrow
import org.junit.jupiter.api.assertThrows
import kotlin.test.assertNotEquals

class RessourcePedagogiqueTest {

    private val video = Media("https://example.com/lesson.mp4")
    private val image = Media("https://example.com/cover.png")

    private fun resource(
        title: String = "Qu'est-ce qu'un ETF ?",
        type: ResourceType = ResourceType.ARTICLE,
        durationMinutes: Int = 5,
        media: Media? = null,
    ) = RessourcePedagogique(title, "Description", "Contenu", type, durationMinutes, ResourceLevel.BEGINNER, media)

    @Test
    fun `should generate a distinct id for each new resource`() {
        assertNotEquals(resource().id, resource().id)
    }

    @Test
    fun `should reject a blank title`() {
        assertThrows<IllegalArgumentException> { resource(title = " ") }
    }

    @Test
    fun `should reject a duration that is not positive`() {
        assertThrows<IllegalArgumentException> { resource(durationMinutes = 0) }
    }

    @Test
    fun `should reject a video resource without media`() {
        assertThrows<IllegalArgumentException> { resource(type = ResourceType.VIDEO) }
    }

    @Test
    fun `should reject a video resource with an image media`() {
        assertThrows<IllegalArgumentException> { resource(type = ResourceType.VIDEO, media = image) }
    }

    @Test
    fun `should accept a video resource with a video media`() {
        assertDoesNotThrow { resource(type = ResourceType.VIDEO, media = video) }
    }

    @Test
    fun `should accept an article with or without media`() {
        assertDoesNotThrow { resource() }
        assertDoesNotThrow { resource(media = image) }
    }
}

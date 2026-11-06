package com.fisa.indice.resource.mappers

import com.fisa.indice.resource.dtos.responses.MediaResponseDto
import com.fisa.indice.resource.entities.ResourceEntity
import com.fisa.indice.resource.models.Media
import com.fisa.indice.resource.models.MediaType
import com.fisa.indice.resource.models.ResourceLevel
import com.fisa.indice.resource.models.ResourceType
import org.junit.jupiter.api.Test
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ResourceMapperTest {

    private val id = UUID.randomUUID()

    private fun entity(mediaUrl: String?) = ResourceEntity(
        id, "La diversification", "Description", "Contenu", ResourceType.VIDEO, 4, ResourceLevel.INTERMEDIATE, mediaUrl,
    )

    @Test
    fun `should map an entity with media to a model`() {
        // When
        val model = entity("https://example.com/bee.mp4").toModel(favourite = true)

        // Then
        assertEquals(id, model.id)
        assertEquals("La diversification", model.title)
        assertEquals("Contenu", model.content)
        assertEquals(4, model.durationMinutes)
        assertEquals(ResourceLevel.INTERMEDIATE, model.level)
        assertEquals(Media("https://example.com/bee.mp4"), model.media)
        assertTrue(model.favourite)
    }

    @Test
    fun `should map an entity without media to a model without media`() {
        // When
        val model = ResourceEntity(id, "Les frais", "Description", "Contenu", ResourceType.ARTICLE, 7, ResourceLevel.BEGINNER, null).toModel()

        // Then
        assertNull(model.media)
    }

    @Test
    fun `should expose the media type deduced from the url`() {
        // When
        val dto = entity("https://example.com/bee.mp4").toModel().toDto()

        // Then
        assertEquals(MediaResponseDto("https://example.com/bee.mp4", MediaType.VIDEO), dto.media)
    }

    @Test
    fun `should include the content only in the detail`() {
        // When
        val detail = entity("https://example.com/bee.mp4").toModel().toDetailDto()

        // Then
        assertEquals("Contenu", detail.content)
    }
}

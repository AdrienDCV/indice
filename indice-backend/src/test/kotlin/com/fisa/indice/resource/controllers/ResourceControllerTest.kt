package com.fisa.indice.resource.controllers

import com.fisa.indice.resource.exceptions.ResourceNotFoundException
import com.fisa.indice.resource.models.Media
import com.fisa.indice.resource.models.ResourceLevel
import com.fisa.indice.resource.models.ResourceType
import com.fisa.indice.resource.models.RessourcePedagogique
import com.fisa.indice.resource.services.ResourceService
import io.mockk.CapturingSlot
import io.mockk.every
import io.mockk.justRun
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest
import org.springframework.context.annotation.Bean
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.Pageable
import org.springframework.data.domain.Sort
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.put
import java.util.UUID
import kotlin.test.assertEquals

@WebMvcTest(ResourceController::class)
class ResourceControllerTest(
    @Autowired private val mockMvc: MockMvc,
    @Autowired private val resourceService: ResourceService,
) {

    @TestConfiguration
    class MockConfig {
        @Bean
        fun resourceService(): ResourceService = mockk()
    }

    private val id = UUID.fromString("00000000-0000-4000-8000-000000000003")
    private val resource = RessourcePedagogique(
        title = "La diversification",
        description = "Pourquoi répartir son investissement.",
        content = "Contenu",
        type = ResourceType.VIDEO,
        durationMinutes = 4,
        level = ResourceLevel.INTERMEDIATE,
        media = Media("https://example.com/bee.mp4"),
        favourite = true,
        id = id,
    )

    private fun givenServiceReturnsOneResource(): CapturingSlot<Pageable> {
        val pageable = slot<Pageable>()
        every { resourceService.retrieveResources(capture(pageable), any(), any(), any()) } answers {
            PageImpl(listOf(resource), pageable.captured, 1)
        }
        return pageable
    }

    @Test
    fun `should return a paginated list of resources without their content`() {
        // Given
        givenServiceReturnsOneResource()

        // When / Then
        mockMvc.get("/resources").andExpect {
            status { isOk() }
            jsonPath("$.content[0].id") { value(id.toString()) }
            jsonPath("$.content[0].title") { value("La diversification") }
            jsonPath("$.content[0].description") { value("Pourquoi répartir son investissement.") }
            jsonPath("$.content[0].content") { doesNotExist() }
            jsonPath("$.content[0].type") { value("VIDEO") }
            jsonPath("$.content[0].durationMinutes") { value(4) }
            jsonPath("$.content[0].level") { value("INTERMEDIATE") }
            jsonPath("$.content[0].media.url") { value("https://example.com/bee.mp4") }
            jsonPath("$.content[0].media.type") { value("VIDEO") }
            jsonPath("$.content[0].favourite") { value(true) }
            jsonPath("$.page") { value(0) }
            jsonPath("$.size") { value(20) }
            jsonPath("$.totalElements") { value(1) }
            jsonPath("$.totalPages") { value(1) }
        }
    }

    @Test
    fun `should sort resources by title by default`() {
        // Given
        val pageable = givenServiceReturnsOneResource()

        // When
        mockMvc.get("/resources").andExpect { status { isOk() } }

        // Then
        assertEquals(Sort.by("title"), pageable.captured.sort)
    }

    @Test
    fun `should not filter resources by default`() {
        // Given
        givenServiceReturnsOneResource()

        // When
        mockMvc.get("/resources").andExpect { status { isOk() } }

        // Then
        verify(exactly = 1) { resourceService.retrieveResources(any(), null, emptySet(), false) }
    }

    @Test
    fun `should pass the search, the levels and the favourites filter to the service`() {
        // Given
        givenServiceReturnsOneResource()

        // When
        mockMvc.get("/resources?search=frais&levels=BEGINNER,EXPERIENCED&favourites=true").andExpect { status { isOk() } }

        // Then
        verify(exactly = 1) {
            resourceService.retrieveResources(any(), "frais", setOf(ResourceLevel.BEGINNER, ResourceLevel.EXPERIENCED), true)
        }
    }

    @Test
    fun `should return bad request when a level is unknown`() {
        mockMvc.get("/resources?levels=EXPERT").andExpect {
            status { isBadRequest() }
            jsonPath("$[0].message") { value("error.request.invalid-parameter") }
        }
    }

    @Test
    fun `should return the resource detail with its content`() {
        every { resourceService.retrieveResource(id) } returns resource

        mockMvc.get("/resources/$id").andExpect {
            status { isOk() }
            jsonPath("$.id") { value(id.toString()) }
            jsonPath("$.content") { value("Contenu") }
            jsonPath("$.media.type") { value("VIDEO") }
            jsonPath("$.favourite") { value(true) }
        }
    }

    @Test
    fun `should return a null media when the resource has none`() {
        every { resourceService.retrieveResource(id) } returns resource.copy(type = ResourceType.ARTICLE, media = null)

        mockMvc.get("/resources/$id").andExpect {
            status { isOk() }
            jsonPath("$.media") { value(null) }
        }
    }

    @Test
    fun `should return not found when the resource is unknown`() {
        every { resourceService.retrieveResource(id) } throws ResourceNotFoundException()

        mockMvc.get("/resources/$id").andExpect {
            status { isNotFound() }
            jsonPath("$[0].message") { value("error.resources.resource-not-found") }
        }
    }

    @Test
    fun `should return bad request when the id is not a uuid`() {
        mockMvc.get("/resources/not-a-uuid").andExpect {
            status { isBadRequest() }
            jsonPath("$[0].message") { value("error.request.invalid-parameter") }
        }
    }

    @Test
    fun `should return the resource detail when a resource is pinned`() {
        every { resourceService.addFavourite(id) } returns resource

        mockMvc.put("/resources/$id/favourite").andExpect {
            status { isOk() }
            jsonPath("$.id") { value(id.toString()) }
            jsonPath("$.favourite") { value(true) }
        }
    }

    @Test
    fun `should return not found when pinning an unknown resource`() {
        every { resourceService.addFavourite(id) } throws ResourceNotFoundException()

        mockMvc.put("/resources/$id/favourite").andExpect {
            status { isNotFound() }
            jsonPath("$[0].message") { value("error.resources.resource-not-found") }
        }
    }

    @Test
    fun `should return no content when a favourite is removed`() {
        justRun { resourceService.removeFavourite(id) }

        mockMvc.delete("/resources/$id/favourite").andExpect { status { isNoContent() } }

        verify(exactly = 1) { resourceService.removeFavourite(id) }
    }
}

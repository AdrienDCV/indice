package com.fisa.indice.resource.services

import com.fisa.indice.resource.entities.FavouriteResourceEntity
import com.fisa.indice.resource.entities.ResourceEntity
import com.fisa.indice.resource.exceptions.ResourceNotFoundException
import com.fisa.indice.resource.models.ResourceLevel
import com.fisa.indice.resource.models.ResourceType
import com.fisa.indice.resource.repositories.FavouriteResourceRepository
import com.fisa.indice.resource.repositories.ResourceRepository
import io.mockk.every
import io.mockk.justRun
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import java.util.Optional
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ResourceServiceTest {

    private val pageable = PageRequest.of(0, 20)
    private val fees = entity("Comprendre les frais")
    private val diversification = entity("La diversification")

    private val resourceRepository = mockk<ResourceRepository>()
    private val favouriteResourceRepository = mockk<FavouriteResourceRepository>()
    private val resourceService = ResourceService(resourceRepository, favouriteResourceRepository)

    private fun entity(title: String) =
        ResourceEntity(UUID.randomUUID(), title, "Description", "Contenu", ResourceType.ARTICLE, 5, ResourceLevel.BEGINNER, null)

    private fun givenCatalog(vararg favourites: ResourceEntity) {
        every { resourceRepository.findInCatalog(any(), any(), any(), any()) } returns PageImpl(listOf(fees, diversification), pageable, 2)
        every { favouriteResourceRepository.findAllById(any()) } returns favourites.map { FavouriteResourceEntity(it.id) }
    }

    @Test
    fun `should search with a trimmed lowercase text`() {
        // Given
        givenCatalog()

        // When
        resourceService.retrieveResources(pageable, "  FRAIS ", emptySet(), favouritesOnly = false)

        // Then
        verify { resourceRepository.findInCatalog("frais", any(), false, pageable) }
    }

    @Test
    fun `should search with an empty text when there is no search`() {
        // Given
        givenCatalog()

        // When
        resourceService.retrieveResources(pageable, null, emptySet(), favouritesOnly = false)

        // Then
        verify { resourceRepository.findInCatalog("", any(), false, pageable) }
    }

    @Test
    fun `should keep every level when no level is chosen`() {
        // Given
        givenCatalog()

        // When
        resourceService.retrieveResources(pageable, null, emptySet(), favouritesOnly = false)

        // Then
        verify { resourceRepository.findInCatalog(any(), ResourceLevel.entries.toSet(), any(), any()) }
    }

    @Test
    fun `should pass the chosen levels and the favourites filter`() {
        // Given
        givenCatalog()
        val levels = setOf(ResourceLevel.BEGINNER, ResourceLevel.EXPERIENCED)

        // When
        resourceService.retrieveResources(pageable, null, levels, favouritesOnly = true)

        // Then
        verify { resourceRepository.findInCatalog("", levels, true, pageable) }
    }

    @Test
    fun `should flag the favourite resources of the page`() {
        // Given
        givenCatalog(diversification)

        // When
        val page = resourceService.retrieveResources(pageable, null, emptySet(), favouritesOnly = false)

        // Then
        assertEquals(listOf(false, true), page.content.map { it.favourite })
        assertEquals(2, page.totalElements)
    }

    @Test
    fun `should return a resource with its favourite state`() {
        // Given
        every { resourceRepository.findById(fees.id) } returns Optional.of(fees)
        every { favouriteResourceRepository.existsById(fees.id) } returns true

        // When
        val resource = resourceService.retrieveResource(fees.id)

        // Then
        assertEquals("Comprendre les frais", resource.title)
        assertTrue(resource.favourite)
    }

    @Test
    fun `should throw ResourceNotFoundException when the resource is unknown`() {
        // Given
        val id = UUID.randomUUID()
        every { resourceRepository.findById(id) } returns Optional.empty()

        // When / Then
        assertThrows<ResourceNotFoundException> { resourceService.retrieveResource(id) }
    }

    @Test
    fun `should pin a resource that was not a favourite`() {
        // Given
        every { resourceRepository.findById(fees.id) } returns Optional.of(fees)
        every { favouriteResourceRepository.existsById(fees.id) } returns false
        every { favouriteResourceRepository.save(any()) } answers { firstArg() }

        // When
        val resource = resourceService.addFavourite(fees.id)

        // Then
        assertTrue(resource.favourite)
        verify(exactly = 1) { favouriteResourceRepository.save(FavouriteResourceEntity(fees.id)) }
    }

    @Test
    fun `should not save a resource that is already a favourite`() {
        // Given
        every { resourceRepository.findById(fees.id) } returns Optional.of(fees)
        every { favouriteResourceRepository.existsById(fees.id) } returns true

        // When
        val resource = resourceService.addFavourite(fees.id)

        // Then
        assertTrue(resource.favourite)
        verify(exactly = 0) { favouriteResourceRepository.save(any()) }
    }

    @Test
    fun `should throw ResourceNotFoundException when pinning an unknown resource`() {
        // Given
        val id = UUID.randomUUID()
        every { resourceRepository.findById(id) } returns Optional.empty()

        // When / Then
        assertThrows<ResourceNotFoundException> { resourceService.addFavourite(id) }
        verify(exactly = 0) { favouriteResourceRepository.save(any()) }
    }

    @Test
    fun `should remove a favourite`() {
        // Given
        justRun { favouriteResourceRepository.deleteById(fees.id) }

        // When
        resourceService.removeFavourite(fees.id)

        // Then
        verify(exactly = 1) { favouriteResourceRepository.deleteById(fees.id) }
    }
}

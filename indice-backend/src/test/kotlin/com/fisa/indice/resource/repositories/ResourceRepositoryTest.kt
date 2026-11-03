package com.fisa.indice.resource.repositories

import com.fisa.indice.resource.entities.FavouriteResourceEntity
import com.fisa.indice.resource.entities.ResourceEntity
import com.fisa.indice.resource.models.ResourceLevel
import com.fisa.indice.resource.models.ResourceType
import jakarta.persistence.EntityManager
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.test.context.ActiveProfiles
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
class ResourceRepositoryTest(
    @Autowired private val resourceRepository: ResourceRepository,
    @Autowired private val favouriteResourceRepository: FavouriteResourceRepository,
    @Autowired private val entityManager: EntityManager,
) {

    private val pageable = PageRequest.of(0, 20, Sort.by("title"))
    private val allLevels = ResourceLevel.entries.toSet()
    private val fees = resource("Comprendre les frais", "Les frais d'un ETF", ResourceLevel.BEGINNER)
    private val diversification = resource("La diversification", "Répartir son investissement", ResourceLevel.INTERMEDIATE)
    private val factsheet = resource("Lire une fiche ETF", "Les informations clés d'un ETF", ResourceLevel.PROFESSIONAL)

    private fun resource(title: String, description: String, level: ResourceLevel) =
        ResourceEntity(UUID.randomUUID(), title, description, "Contenu", ResourceType.ARTICLE, 5, level, null)

    @BeforeEach
    fun givenResources() {
        favouriteResourceRepository.deleteAllInBatch()
        resourceRepository.deleteAllInBatch()
        resourceRepository.saveAll(listOf(fees, diversification, factsheet))
        favouriteResourceRepository.save(FavouriteResourceEntity(diversification.id))
        entityManager.flush()
    }

    private fun titlesFound(search: String = "", levels: Set<ResourceLevel> = allLevels, favouritesOnly: Boolean = false) =
        resourceRepository.findInCatalog(search, levels, favouritesOnly, pageable).content.map { it.title }

    @Test
    fun `should return every resource sorted by title for an empty search`() {
        assertEquals(listOf("Comprendre les frais", "La diversification", "Lire une fiche ETF"), titlesFound())
    }

    @Test
    fun `should find resources whose title contains the search`() {
        assertEquals(listOf("La diversification"), titlesFound("divers"))
    }

    @Test
    fun `should find resources whose description contains the search`() {
        assertEquals(listOf("Comprendre les frais", "Lire une fiche ETF"), titlesFound("etf"))
    }

    @Test
    fun `should keep only the resources of the given levels`() {
        assertEquals(
            listOf("Comprendre les frais", "Lire une fiche ETF"),
            titlesFound(levels = setOf(ResourceLevel.BEGINNER, ResourceLevel.PROFESSIONAL)),
        )
    }

    @Test
    fun `should keep only favourites`() {
        assertEquals(listOf("La diversification"), titlesFound(favouritesOnly = true))
    }

    @Test
    fun `should combine search, levels and favourites`() {
        assertEquals(emptyList(), titlesFound("frais", setOf(ResourceLevel.BEGINNER), favouritesOnly = true))
        assertEquals(listOf("La diversification"), titlesFound("divers", setOf(ResourceLevel.INTERMEDIATE), favouritesOnly = true))
    }

    @Test
    fun `should remove the favourite with its resource`() {
        // When
        resourceRepository.deleteById(diversification.id)
        entityManager.flush()
        entityManager.clear()

        // Then
        assertFalse(favouriteResourceRepository.existsById(diversification.id))
    }
}

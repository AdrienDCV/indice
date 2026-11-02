package com.fisa.indice.etf.repositories

import com.fisa.indice.etf.entities.EtfEntity
import com.fisa.indice.etf.entities.FavouriteEtfEntity
import jakarta.persistence.EntityManager
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.test.context.ActiveProfiles
import java.time.Instant
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
class EtfRepositoryTest(
    @Autowired private val etfRepository: EtfRepository,
    @Autowired private val favouriteEtfRepository: FavouriteEtfRepository,
    @Autowired private val entityManager: EntityManager,
) {

    private val now = Instant.parse("2026-11-01T08:00:00Z")
    private val pageable = PageRequest.of(0, 20, Sort.by("name"))

    @BeforeEach
    fun givenCatalog() {
        favouriteEtfRepository.deleteAllInBatch()
        etfRepository.deleteAllInBatch()
        etfRepository.saveAll(
            listOf(
                EtfEntity(UUID.randomUUID(), "SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", now),
                EtfEntity(UUID.randomUUID(), "VGK", "NYSE", "Vanguard FTSE Europe ETF", "USD", now),
                EtfEntity(UUID.randomUUID(), "BND", "NASDAQ", "Vanguard Total Bond Market ETF", "USD", now),
            )
        )
        favouriteEtfRepository.save(FavouriteEtfEntity("VGK"))
        entityManager.flush()
    }

    private fun tickersFound(search: String, favouritesOnly: Boolean = false) =
        etfRepository.findInCatalog(search, favouritesOnly, pageable).content.map { it.ticker }

    @Test
    fun `should return the whole catalog sorted by name for an empty search`() {
        assertEquals(listOf("SPY", "VGK", "BND"), tickersFound(""))
    }

    @Test
    fun `should find etfs whose ticker starts with the search`() {
        assertEquals(listOf("SPY"), tickersFound("sp"))
    }

    @Test
    fun `should not find etfs whose ticker only contains the search`() {
        assertEquals(emptyList(), tickersFound("py"))
    }

    @Test
    fun `should find etfs whose name contains the search whatever the case`() {
        assertEquals(listOf("VGK", "BND"), tickersFound("vanguard"))
    }

    @Test
    fun `should only return favourites when asked`() {
        assertEquals(listOf("VGK"), tickersFound("", favouritesOnly = true))
    }

    @Test
    fun `should combine the search and the favourites filter`() {
        assertEquals(emptyList(), tickersFound("bond", favouritesOnly = true))
    }

    @Test
    fun `should paginate the results`() {
        val page = etfRepository.findInCatalog("", false, PageRequest.of(1, 2, Sort.by("name")))

        assertEquals(listOf("BND"), page.content.map { it.ticker })
        assertEquals(3, page.totalElements)
    }

    @Test
    fun `should delete the favourite of an etf removed from the catalog`() {
        // Given
        val vgk = checkNotNull(etfRepository.findByTicker("VGK"))

        // When
        etfRepository.deleteAllByIdInBatch(listOf(vgk.id))
        entityManager.clear()

        // Then
        assertFalse(favouriteEtfRepository.existsById("VGK"))
    }
}

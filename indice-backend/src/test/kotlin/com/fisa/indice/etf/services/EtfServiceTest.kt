package com.fisa.indice.etf.services

import com.fisa.indice.etf.clients.TwelveDataClient
import com.fisa.indice.etf.config.EtfCatalogProperties
import com.fisa.indice.etf.dtos.twelvedata.TwelveDataEtfDto
import com.fisa.indice.etf.entities.EtfEntity
import com.fisa.indice.etf.entities.FavouriteEtfEntity
import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.exceptions.InvalidTickerException
import com.fisa.indice.etf.exceptions.TwelveDataUnavailableException
import com.fisa.indice.etf.repositories.EtfRepository
import com.fisa.indice.etf.repositories.FavouriteEtfRepository
import io.mockk.CapturingSlot
import io.mockk.every
import io.mockk.justRun
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EtfServiceTest {

    private val now = Instant.parse("2026-10-07T08:00:00Z")
    private val yesterday = now.minus(Duration.ofDays(1))
    private val lastWeek = now.minus(Duration.ofDays(8))
    private val first = "SPY"
    private val second = "QQQ"
    private val country = "United States"
    private val pageable = PageRequest.of(0, 20)

    private val etfRepository = mockk<EtfRepository>()
    private val twelveDataClient = mockk<TwelveDataClient>()
    private val favouriteEtfRepository = mockk<FavouriteEtfRepository> {
        every { findAllById(any()) } returns emptyList()
    }
    private val etfService = EtfService(
        etfRepository,
        twelveDataClient,
        Clock.fixed(now, ZoneOffset.UTC),
        EtfCatalogProperties(country),
        favouriteEtfRepository,
    )

    private fun entity(ticker: String, fetchedAt: Instant) =
        EtfEntity(UUID.randomUUID(), ticker, "NYSE", "ETF $ticker", "USD", fetchedAt)

    private fun etf(ticker: String) = TwelveDataEtfDto(ticker, "ETF $ticker", "USD", "NYSE")

    private fun givenStoredEtfs(vararg entities: EtfEntity) {
        every { etfRepository.findFirstByOrderByFetchedAtDesc() } returns entities.maxByOrNull { it.fetchedAt }
        every { etfRepository.findAll() } returns entities.toList()
        every { etfRepository.findInCatalog("", false, pageable) } returns PageImpl(entities.toList(), pageable, entities.size.toLong())
    }

    private fun givenSaveAllReturnsItsArgument(): CapturingSlot<List<EtfEntity>> {
        val saved = slot<List<EtfEntity>>()
        every { etfRepository.saveAll(capture(saved)) } answers { saved.captured }
        return saved
    }

    @Test
    fun `should return requested page without calling twelve data when catalog is up to date`() {
        // Given
        givenStoredEtfs(entity(first, yesterday))

        // When
        val result = etfService.retrieveEtfs(pageable, search = null, favouritesOnly = false)

        // Then
        verify(exactly = 0) { twelveDataClient.fetchEtfs(any()) }
        verify(exactly = 0) { etfRepository.findAll() }
        verify(exactly = 0) { etfRepository.saveAll(any<List<EtfEntity>>()) }
        assertEquals(listOf(first), result.etfs.content.map { it.ticker })
        assertEquals(yesterday, result.lastSynchronizedAt)
        assertFalse(result.stale)
    }

    @Test
    fun `should synchronize catalog once then return requested page when catalog is stale`() {
        // Given
        givenStoredEtfs(entity(first, lastWeek))
        every { twelveDataClient.fetchEtfs(country) } returns listOf(etf(first), etf(second))
        val saved = givenSaveAllReturnsItsArgument()

        // When
        val result = etfService.retrieveEtfs(pageable, search = null, favouritesOnly = false)

        // Then
        verify(exactly = 1) { twelveDataClient.fetchEtfs(country) }
        verify(exactly = 0) { etfRepository.deleteAllByIdInBatch(any()) }
        verify(exactly = 1) { etfRepository.findInCatalog("", false, pageable) }
        assertEquals(setOf(first, second), saved.captured.map { it.ticker }.toSet())
        assertTrue(saved.captured.all { it.fetchedAt == now })
        assertEquals(now, result.lastSynchronizedAt)
        assertFalse(result.stale)
    }

    @Test
    fun `should delete etfs absent from twelve data response`() {
        // Given
        val absent = entity(second, lastWeek)
        givenStoredEtfs(entity(first, lastWeek), absent)
        every { twelveDataClient.fetchEtfs(country) } returns listOf(etf(first))
        justRun { etfRepository.deleteAllByIdInBatch(any()) }
        val saved = givenSaveAllReturnsItsArgument()

        // When
        etfService.retrieveEtfs(pageable, search = null, favouritesOnly = false)

        // Then
        verify(exactly = 1) { etfRepository.deleteAllByIdInBatch(listOf(absent.id)) }
        assertEquals(listOf(first), saved.captured.map { it.ticker })
    }

    @Test
    fun `should keep every etf of twelve data response`() {
        // Given
        givenStoredEtfs()
        every { twelveDataClient.fetchEtfs(country) } returns listOf(etf("ARKK"), etf(first))
        val saved = givenSaveAllReturnsItsArgument()

        // When
        etfService.retrieveEtfs(pageable, search = null, favouritesOnly = false)

        // Then
        assertEquals(listOf("ARKK", first), saved.captured.map { it.ticker })
    }

    @Test
    fun `should keep stored etfs flagged as stale when twelve data response is empty`() {
        // Given
        givenStoredEtfs(entity(first, lastWeek))
        every { twelveDataClient.fetchEtfs(country) } returns emptyList()

        // When
        val result = etfService.retrieveEtfs(pageable, search = null, favouritesOnly = false)

        // Then
        verify(exactly = 0) { etfRepository.deleteAllByIdInBatch(any()) }
        verify(exactly = 0) { etfRepository.saveAll(any<List<EtfEntity>>()) }
        assertTrue(result.stale)
        assertEquals(lastWeek, result.lastSynchronizedAt)
        assertEquals(listOf(first), result.etfs.content.map { it.ticker })
    }

    @Test
    fun `should return stored etfs flagged as stale when twelve data is unavailable`() {
        // Given
        givenStoredEtfs(entity(first, lastWeek))
        every { twelveDataClient.fetchEtfs(any()) } throws TwelveDataUnavailableException()

        // When
        val result = etfService.retrieveEtfs(pageable, search = null, favouritesOnly = false)

        // Then
        verify(exactly = 0) { etfRepository.saveAll(any<List<EtfEntity>>()) }
        assertTrue(result.stale)
        assertEquals(listOf(first), result.etfs.content.map { it.ticker })
    }

    @Test
    fun `should return empty stale page when database is empty and twelve data is unavailable`() {
        // Given
        givenStoredEtfs()
        every { twelveDataClient.fetchEtfs(any()) } throws TwelveDataUnavailableException()

        // When
        val result = etfService.retrieveEtfs(pageable, search = null, favouritesOnly = false)

        // Then
        assertTrue(result.etfs.isEmpty)
        assertNull(result.lastSynchronizedAt)
        assertTrue(result.stale)
    }

    @Test
    fun `should search the catalog with a trimmed lower case text and the favourites filter`() {
        // Given
        givenStoredEtfs(entity(first, yesterday))
        every { etfRepository.findInCatalog("van", true, pageable) } returns PageImpl(emptyList(), pageable, 0)

        // When
        val result = etfService.retrieveEtfs(pageable, search = "  VAN ", favouritesOnly = true)

        // Then
        verify(exactly = 1) { etfRepository.findInCatalog("van", true, pageable) }
        assertTrue(result.etfs.isEmpty)
    }

    @Test
    fun `should tell which etfs of the page are favourites`() {
        // Given
        givenStoredEtfs(entity(first, yesterday), entity(second, yesterday))
        every { favouriteEtfRepository.findAllById(listOf(first, second)) } returns listOf(FavouriteEtfEntity(first))

        // When
        val result = etfService.retrieveEtfs(pageable, search = null, favouritesOnly = false)

        // Then
        assertEquals(mapOf(first to true, second to false), result.etfs.content.associate { it.ticker to it.favourite })
    }

    @Test
    fun `should pin an etf that was not a favourite yet`() {
        // Given
        every { etfRepository.findByTicker(first) } returns entity(first, yesterday)
        every { favouriteEtfRepository.existsById(first) } returns false
        every { favouriteEtfRepository.save(FavouriteEtfEntity(first)) } returns FavouriteEtfEntity(first)

        // When
        val added = etfService.addFavourite(" spy ")

        // Then
        assertTrue(added)
        verify(exactly = 1) { favouriteEtfRepository.save(FavouriteEtfEntity(first)) }
    }

    @Test
    fun `should not pin an etf twice`() {
        // Given
        every { etfRepository.findByTicker(first) } returns entity(first, yesterday)
        every { favouriteEtfRepository.existsById(first) } returns true

        // When
        val added = etfService.addFavourite(first)

        // Then
        assertFalse(added)
        verify(exactly = 0) { favouriteEtfRepository.save(any()) }
    }

    @Test
    fun `should throw EtfNotFoundException when pinning an etf outside the catalog`() {
        every { etfRepository.findByTicker("ARKK") } returns null

        assertThrows<EtfNotFoundException> { etfService.addFavourite("ARKK") }
    }

    @Test
    fun `should throw InvalidTickerException when pinning an invalid ticker`() {
        assertThrows<InvalidTickerException> { etfService.addFavourite("SP Y") }
    }

    @Test
    fun `should unpin an etf`() {
        // Given
        justRun { favouriteEtfRepository.deleteById(first) }

        // When
        etfService.removeFavourite(" spy ")

        // Then
        verify(exactly = 1) { favouriteEtfRepository.deleteById(first) }
    }

    @Test
    fun `should throw InvalidTickerException when unpinning an invalid ticker`() {
        assertThrows<InvalidTickerException> { etfService.removeFavourite("SP Y") }
    }
}

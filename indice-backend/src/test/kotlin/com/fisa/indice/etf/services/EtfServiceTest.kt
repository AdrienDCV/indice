package com.fisa.indice.etf.services

import com.fisa.indice.etf.clients.EodhdClient
import com.fisa.indice.etf.config.EtfCatalogProperties
import com.fisa.indice.etf.dtos.responses.EodhdSymbolDto
import com.fisa.indice.etf.entities.EtfEntity
import com.fisa.indice.etf.exceptions.EodhdDataUnavailableException
import com.fisa.indice.etf.repositories.EtfRepository
import io.mockk.CapturingSlot
import io.mockk.every
import io.mockk.justRun
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.Test
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
    private val first = "LU1681043599"
    private val second = "LU1681048804"
    private val pageable = PageRequest.of(0, 20)

    private val etfRepository = mockk<EtfRepository>()
    private val eodhdClient = mockk<EodhdClient>()
    private val etfService = EtfService(
        etfRepository,
        eodhdClient,
        Clock.fixed(now, ZoneOffset.UTC),
        EtfCatalogProperties(setOf(first, second)),
    )

    private fun entity(isin: String, fetchedAt: Instant) =
        EtfEntity(UUID.randomUUID(), isin, "T-$isin", "PA", "ETF $isin", "EUR", fetchedAt)

    private fun symbol(isin: String?) = EodhdSymbolDto("T-$isin", "ETF $isin", "PA", "EUR", isin)

    private fun givenStoredEtfs(vararg entities: EtfEntity) {
        every { etfRepository.findFirstByOrderByFetchedAtDesc() } returns entities.maxByOrNull { it.fetchedAt }
        every { etfRepository.findAll() } returns entities.toList()
        every { etfRepository.findAll(pageable) } returns PageImpl(entities.toList(), pageable, entities.size.toLong())
    }

    private fun givenSaveAllReturnsItsArgument(): CapturingSlot<List<EtfEntity>> {
        val saved = slot<List<EtfEntity>>()
        every { etfRepository.saveAll(capture(saved)) } answers { saved.captured }
        return saved
    }

    @Test
    fun `should return requested page without calling eodhd when catalog is up to date`() {
        // Given
        givenStoredEtfs(entity(first, yesterday))

        // When
        val result = etfService.retrieveEtfs(pageable)

        // Then
        verify(exactly = 0) { eodhdClient.fetchEtfs(any()) }
        verify(exactly = 0) { etfRepository.findAll() }
        verify(exactly = 0) { etfRepository.saveAll(any<List<EtfEntity>>()) }
        assertEquals(listOf(first), result.etfs.content.map { it.isin })
        assertEquals(yesterday, result.lastSynchronizedAt)
        assertFalse(result.stale)
    }

    @Test
    fun `should synchronize catalog once then return requested page when catalog is stale`() {
        // Given
        givenStoredEtfs(entity(first, lastWeek))
        every { eodhdClient.fetchEtfs(EtfService.EXCHANGE) } returns listOf(symbol(first), symbol(second))
        val saved = givenSaveAllReturnsItsArgument()

        // When
        val result = etfService.retrieveEtfs(pageable)

        // Then
        verify(exactly = 1) { eodhdClient.fetchEtfs(EtfService.EXCHANGE) }
        verify(exactly = 0) { etfRepository.deleteAllByIdInBatch(any()) }
        verify(exactly = 1) { etfRepository.findAll(pageable) }
        assertEquals(setOf(first, second), saved.captured.map { it.isin }.toSet())
        assertTrue(saved.captured.all { it.fetchedAt == now })
        assertEquals(now, result.lastSynchronizedAt)
        assertFalse(result.stale)
    }

    @Test
    fun `should delete etfs absent from eodhd response`() {
        // Given
        val absent = entity(second, lastWeek)
        givenStoredEtfs(entity(first, lastWeek), absent)
        every { eodhdClient.fetchEtfs(EtfService.EXCHANGE) } returns listOf(symbol(first))
        justRun { etfRepository.deleteAllByIdInBatch(any()) }
        val saved = givenSaveAllReturnsItsArgument()

        // When
        etfService.retrieveEtfs(pageable)

        // Then
        verify(exactly = 1) { etfRepository.deleteAllByIdInBatch(listOf(absent.id)) }
        assertEquals(listOf(first), saved.captured.map { it.isin })
    }

    @Test
    fun `should ignore eodhd entries that are not selected or have no isin`() {
        // Given
        givenStoredEtfs()
        every { eodhdClient.fetchEtfs(EtfService.EXCHANGE) } returns listOf(symbol(null), symbol("XS0000000000"), symbol(first))
        val saved = givenSaveAllReturnsItsArgument()

        // When
        etfService.retrieveEtfs(pageable)

        // Then
        assertEquals(listOf(first), saved.captured.map { it.isin })
    }

    @Test
    fun `should keep stored etfs flagged as stale when eodhd response contains no selected etf`() {
        // Given
        givenStoredEtfs(entity(first, lastWeek))
        every { eodhdClient.fetchEtfs(EtfService.EXCHANGE) } returns listOf(symbol("XS0000000000"))

        // When
        val result = etfService.retrieveEtfs(pageable)

        // Then
        verify(exactly = 0) { etfRepository.deleteAllByIdInBatch(any()) }
        verify(exactly = 0) { etfRepository.saveAll(any<List<EtfEntity>>()) }
        assertTrue(result.stale)
        assertEquals(lastWeek, result.lastSynchronizedAt)
        assertEquals(listOf(first), result.etfs.content.map { it.isin })
    }

    @Test
    fun `should return stored etfs flagged as stale when eodhd is unavailable`() {
        // Given
        givenStoredEtfs(entity(first, lastWeek))
        every { eodhdClient.fetchEtfs(any()) } throws EodhdDataUnavailableException()

        // When
        val result = etfService.retrieveEtfs(pageable)

        // Then
        verify(exactly = 0) { etfRepository.saveAll(any<List<EtfEntity>>()) }
        assertTrue(result.stale)
        assertEquals(listOf(first), result.etfs.content.map { it.isin })
    }

    @Test
    fun `should return empty stale page when database is empty and eodhd is unavailable`() {
        // Given
        givenStoredEtfs()
        every { eodhdClient.fetchEtfs(any()) } throws EodhdDataUnavailableException()

        // When
        val result = etfService.retrieveEtfs(pageable)

        // Then
        assertTrue(result.etfs.isEmpty)
        assertNull(result.lastSynchronizedAt)
        assertTrue(result.stale)
    }
}

package com.fisa.indice.etf.services

import com.fisa.indice.etf.clients.TwelveDataClient
import com.fisa.indice.etf.dtos.twelvedata.TwelveDataPriceDto
import com.fisa.indice.etf.entities.EtfClosingPriceEntity
import com.fisa.indice.etf.entities.EtfEntity
import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.exceptions.InvalidTickerException
import com.fisa.indice.etf.exceptions.TwelveDataUnavailableException
import com.fisa.indice.etf.repositories.EtfClosingPriceRepository
import com.fisa.indice.etf.repositories.EtfRepository
import io.mockk.CapturingSlot
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.math.BigDecimal
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EtfDetailServiceTest {

    private val now = Instant.parse("2026-10-20T08:00:00Z")
    private val etf = EtfEntity(UUID.randomUUID(), "SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", now)

    private val etfRepository = mockk<EtfRepository>()
    private val etfClosingPriceRepository = mockk<EtfClosingPriceRepository>()
    private val twelveDataClient = mockk<TwelveDataClient>()
    private val etfDetailService = EtfDetailService(
        etfRepository,
        etfClosingPriceRepository,
        twelveDataClient,
        Clock.fixed(now, ZoneOffset.UTC),
    )

    private fun storedPrice(date: String, close: String, fetchedAt: Instant) =
        EtfClosingPriceEntity(etf.id, LocalDate.parse(date), BigDecimal(close), fetchedAt)

    private fun givenStoredPrices(vararg prices: EtfClosingPriceEntity) {
        every { etfRepository.findByTicker("SPY") } returns etf
        every { etfClosingPriceRepository.findFirstByEtfIdOrderByFetchedAtDesc(etf.id) } returns prices.maxByOrNull { it.fetchedAt }
        every { etfClosingPriceRepository.findAllByEtfIdOrderByTradingDateAsc(etf.id) } returns prices.toList()
    }

    private fun givenReplacementSucceeds(): CapturingSlot<List<EtfClosingPriceEntity>> {
        val saved = slot<List<EtfClosingPriceEntity>>()
        every { etfClosingPriceRepository.deleteAllByEtfId(etf.id) } returns 2
        every { etfClosingPriceRepository.saveAll(capture(saved)) } answers { saved.captured }
        return saved
    }

    @Test
    fun `should reject an invalid ticker without querying the database`() {
        assertThrows<InvalidTickerException> { etfDetailService.retrieveEtf("SP Y") }

        verify(exactly = 0) { etfRepository.findByTicker(any()) }
    }

    @Test
    fun `should throw EtfNotFoundException when ticker is not in the catalog`() {
        every { etfRepository.findByTicker("ARKK") } returns null

        assertThrows<EtfNotFoundException> { etfDetailService.retrieveEtf("arkk") }
    }

    @Test
    fun `should compute market data from stored prices without calling twelve data when prices are fresh`() {
        // Given
        val fetchedAt = now.minus(Duration.ofHours(2))
        givenStoredPrices(storedPrice("2025-10-17", "100", fetchedAt), storedPrice("2026-10-19", "110", fetchedAt))

        // When
        val detail = etfDetailService.retrieveEtf("spy")

        // Then
        verify(exactly = 0) { twelveDataClient.fetchDailyClosingPrices(any(), any()) }
        assertEquals(BigDecimal("0.1000"), detail.marketData?.returnOneYear)
        assertEquals(fetchedAt, detail.closingPricesFetchedAt)
        assertFalse(detail.stale)
    }

    @Test
    fun `should fetch, replace and use new prices when stored prices are stale`() {
        // Given
        val lastWeek = now.minus(Duration.ofDays(7))
        givenStoredPrices(storedPrice("2025-10-10", "100", lastWeek))
        every { twelveDataClient.fetchDailyClosingPrices("SPY", LocalDate.parse("2021-10-13")) } returns listOf(
            TwelveDataPriceDto(LocalDate.parse("2025-10-17"), BigDecimal("100")),
            TwelveDataPriceDto(LocalDate.parse("2026-10-19"), BigDecimal("120")),
        )
        val saved = givenReplacementSucceeds()

        // When
        val detail = etfDetailService.retrieveEtf("SPY")

        // Then
        verify(exactly = 1) { twelveDataClient.fetchDailyClosingPrices("SPY", LocalDate.parse("2021-10-13")) }
        verify(exactly = 1) { etfClosingPriceRepository.deleteAllByEtfId(etf.id) }
        assertEquals(2, saved.captured.size)
        assertTrue(saved.captured.all { it.fetchedAt == now && it.etfId == etf.id })
        assertEquals(BigDecimal("0.2000"), detail.marketData?.returnOneYear)
        assertEquals(now, detail.closingPricesFetchedAt)
        assertFalse(detail.stale)
    }

    @Test
    fun `should return stored prices flagged as stale when twelve data is unavailable`() {
        // Given
        val lastWeek = now.minus(Duration.ofDays(7))
        givenStoredPrices(storedPrice("2025-10-10", "100", lastWeek), storedPrice("2026-10-12", "105", lastWeek))
        every { twelveDataClient.fetchDailyClosingPrices(any(), any()) } throws TwelveDataUnavailableException()

        // When
        val detail = etfDetailService.retrieveEtf("SPY")

        // Then
        verify(exactly = 0) { etfClosingPriceRepository.deleteAllByEtfId(any()) }
        verify(exactly = 0) { etfClosingPriceRepository.saveAll(any<List<EtfClosingPriceEntity>>()) }
        assertNotNull(detail.marketData)
        assertEquals(lastWeek, detail.closingPricesFetchedAt)
        assertTrue(detail.stale)
    }

    @Test
    fun `should return no market data flagged as stale when no price was ever fetched and twelve data is unavailable`() {
        // Given
        givenStoredPrices()
        every { twelveDataClient.fetchDailyClosingPrices(any(), any()) } throws TwelveDataUnavailableException()

        // When
        val detail = etfDetailService.retrieveEtf("SPY")

        // Then
        assertNull(detail.marketData)
        assertNull(detail.closingPricesFetchedAt)
        assertTrue(detail.stale)
        assertEquals("SPY", detail.etf.ticker)
    }
}

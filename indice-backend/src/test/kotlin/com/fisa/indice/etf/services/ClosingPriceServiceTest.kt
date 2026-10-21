package com.fisa.indice.etf.services

import com.fisa.indice.etf.clients.TwelveDataClient
import com.fisa.indice.etf.dtos.twelvedata.TwelveDataPriceDto
import com.fisa.indice.etf.entities.EtfClosingPriceEntity
import com.fisa.indice.etf.exceptions.TwelveDataUnavailableException
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.repositories.EtfClosingPriceRepository
import io.mockk.CapturingSlot
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.Test
import java.math.BigDecimal
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ClosingPriceServiceTest {

    private val now = Instant.parse("2026-10-20T08:00:00Z")
    private val etf = Etf("SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", now)

    private val etfClosingPriceRepository = mockk<EtfClosingPriceRepository>()
    private val twelveDataClient = mockk<TwelveDataClient>()
    private val closingPriceService = ClosingPriceService(
        etfClosingPriceRepository,
        twelveDataClient,
        Clock.fixed(now, ZoneOffset.UTC),
    )

    private fun storedPrice(date: String, close: String, fetchedAt: Instant) =
        EtfClosingPriceEntity(etf.id, LocalDate.parse(date), BigDecimal(close), fetchedAt)

    private fun givenStoredPrices(vararg prices: EtfClosingPriceEntity) {
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
    fun `should return stored history without calling twelve data when prices are fresh`() {
        // Given
        val fetchedAt = now.minus(Duration.ofHours(2))
        givenStoredPrices(storedPrice("2025-10-17", "100", fetchedAt), storedPrice("2026-10-19", "110", fetchedAt))

        // When
        val prices = closingPriceService.retrievePrices(etf)

        // Then
        verify(exactly = 0) { twelveDataClient.fetchDailyClosingPrices(any(), any()) }
        assertEquals(2, prices.history?.prices?.size)
        assertEquals(fetchedAt, prices.fetchedAt)
        assertFalse(prices.stale)
    }

    @Test
    fun `should fetch, replace and use new prices when stored prices are stale`() {
        // Given
        val lastWeek = now.minus(Duration.ofDays(7))
        givenStoredPrices(storedPrice("2025-10-10", "100", lastWeek))
        every { twelveDataClient.fetchDailyClosingPrices("SPY", LocalDate.parse("2021-10-13")) } returns listOf(
            TwelveDataPriceDto(LocalDate.parse("2026-10-19"), BigDecimal("120")),
            TwelveDataPriceDto(LocalDate.parse("2025-10-17"), BigDecimal("100")),
        )
        val saved = givenReplacementSucceeds()

        // When
        val prices = closingPriceService.retrievePrices(etf)

        // Then
        verify(exactly = 1) { twelveDataClient.fetchDailyClosingPrices("SPY", LocalDate.parse("2021-10-13")) }
        verify(exactly = 1) { etfClosingPriceRepository.deleteAllByEtfId(etf.id) }
        verify(exactly = 0) { etfClosingPriceRepository.findAllByEtfIdOrderByTradingDateAsc(any()) }
        assertEquals(2, saved.captured.size)
        assertTrue(saved.captured.all { it.fetchedAt == now && it.etfId == etf.id })
        assertEquals(LocalDate.parse("2025-10-17"), prices.history?.historyStartDate())
        assertEquals(now, prices.fetchedAt)
        assertFalse(prices.stale)
    }

    @Test
    fun `should return stored history flagged as stale when twelve data is unavailable`() {
        // Given
        val lastWeek = now.minus(Duration.ofDays(7))
        givenStoredPrices(storedPrice("2025-10-10", "100", lastWeek), storedPrice("2026-10-12", "105", lastWeek))
        every { twelveDataClient.fetchDailyClosingPrices(any(), any()) } throws TwelveDataUnavailableException()

        // When
        val prices = closingPriceService.retrievePrices(etf)

        // Then
        verify(exactly = 0) { etfClosingPriceRepository.deleteAllByEtfId(any()) }
        verify(exactly = 0) { etfClosingPriceRepository.saveAll(any<List<EtfClosingPriceEntity>>()) }
        assertNotNull(prices.history)
        assertEquals(lastWeek, prices.fetchedAt)
        assertTrue(prices.stale)
    }

    @Test
    fun `should return no history flagged as stale when no price was ever fetched and twelve data is unavailable`() {
        // Given
        givenStoredPrices()
        every { twelveDataClient.fetchDailyClosingPrices(any(), any()) } throws TwelveDataUnavailableException()

        // When
        val prices = closingPriceService.retrievePrices(etf)

        // Then
        assertNull(prices.history)
        assertNull(prices.fetchedAt)
        assertTrue(prices.stale)
    }
}

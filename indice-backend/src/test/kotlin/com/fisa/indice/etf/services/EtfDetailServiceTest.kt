package com.fisa.indice.etf.services

import com.fisa.indice.etf.entities.EtfEntity
import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.exceptions.InvalidTickerException
import com.fisa.indice.etf.models.ClosingPrice
import com.fisa.indice.etf.models.ClosingPriceHistory
import com.fisa.indice.etf.models.EtfPrices
import com.fisa.indice.etf.repositories.EtfRepository
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EtfDetailServiceTest {

    private val now = Instant.parse("2026-10-20T08:00:00Z")
    private val etf = EtfEntity(UUID.randomUUID(), "SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", now)

    private val etfRepository = mockk<EtfRepository>()
    private val closingPriceService = mockk<ClosingPriceService>()
    private val etfDetailService = EtfDetailService(etfRepository, closingPriceService)

    private fun price(date: String, close: String) = ClosingPrice(LocalDate.parse(date), BigDecimal(close))

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
    fun `should compute market data from the etf prices`() {
        // Given
        every { etfRepository.findByTicker("SPY") } returns etf
        val history = ClosingPriceHistory(listOf(price("2025-10-17", "100"), price("2026-10-19", "110")))
        every { closingPriceService.retrievePrices(match { it.ticker == "SPY" }) } returns
            EtfPrices(history, now, stale = false)

        // When
        val detail = etfDetailService.retrieveEtf("spy")

        // Then
        assertEquals(BigDecimal("0.1000"), detail.marketData?.returnOneYear)
        assertEquals(now, detail.closingPricesFetchedAt)
        assertFalse(detail.stale)
    }

    @Test
    fun `should return no market data when no history is available`() {
        // Given
        every { etfRepository.findByTicker("SPY") } returns etf
        every { closingPriceService.retrievePrices(any()) } returns EtfPrices(null, null, stale = true)

        // When
        val detail = etfDetailService.retrieveEtf("SPY")

        // Then
        assertNull(detail.marketData)
        assertNull(detail.closingPricesFetchedAt)
        assertTrue(detail.stale)
        assertEquals("SPY", detail.etf.ticker)
    }
}

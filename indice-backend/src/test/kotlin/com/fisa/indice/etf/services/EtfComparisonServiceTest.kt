package com.fisa.indice.etf.services

import com.fisa.indice.etf.entities.EtfEntity
import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.exceptions.InvalidTickerException
import com.fisa.indice.etf.exceptions.SameEtfComparisonException
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

class EtfComparisonServiceTest {

    private val now = Instant.parse("2026-10-20T08:00:00Z")
    private val spy = EtfEntity(UUID.randomUUID(), "SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", now)
    private val qqq = EtfEntity(UUID.randomUUID(), "QQQ", "NASDAQ", "Invesco QQQ Trust", "USD", now)

    private val etfRepository = mockk<EtfRepository>()
    private val closingPriceService = mockk<ClosingPriceService>()
    private val etfComparisonService = EtfComparisonService(etfRepository, closingPriceService)

    private fun history(vararg closes: Pair<String, String>) = EtfPrices(
        ClosingPriceHistory(closes.map { (date, close) -> ClosingPrice(LocalDate.parse(date), BigDecimal(close)) }),
        now,
        stale = false,
    )

    @Test
    fun `should reject the same etf on both sides without retrieving any history`() {
        assertThrows<SameEtfComparisonException> { etfComparisonService.compare("SPY", " spy ") }

        verify(exactly = 0) { etfRepository.findByTicker(any()) }
        verify(exactly = 0) { closingPriceService.retrievePrices(any()) }
    }

    @Test
    fun `should reject an invalid ticker`() {
        assertThrows<InvalidTickerException> { etfComparisonService.compare("SPY", "QQ Q") }
    }

    @Test
    fun `should throw EtfNotFoundException when one etf is not in the catalog`() {
        // Given
        every { etfRepository.findByTicker("SPY") } returns spy
        every { etfRepository.findByTicker("ARKK") } returns null

        // When / Then
        assertThrows<EtfNotFoundException> { etfComparisonService.compare("SPY", "ARKK") }
        verify(exactly = 0) { closingPriceService.retrievePrices(any()) }
    }

    @Test
    fun `should compare both etfs on their prices`() {
        // Given
        every { etfRepository.findByTicker("SPY") } returns spy
        every { etfRepository.findByTicker("QQQ") } returns qqq
        every { closingPriceService.retrievePrices(match { it.ticker == "SPY" }) } returns
            history("2025-10-17" to "100", "2026-04-01" to "105", "2026-10-19" to "110")
        every { closingPriceService.retrievePrices(match { it.ticker == "QQQ" }) } returns
            history("2025-10-17" to "50", "2026-04-01" to "55", "2026-10-19" to "60")

        // When
        val comparison = etfComparisonService.compare("spy", "qqq")

        // Then
        assertEquals("SPY", comparison.etfA.etf.ticker)
        assertEquals("QQQ", comparison.etfB.etf.ticker)
        assertEquals(BigDecimal("0.1000"), comparison.etfA.performance.totalReturn)
        assertEquals(BigDecimal("0.2000"), comparison.etfB.performance.totalReturn)
    }
}

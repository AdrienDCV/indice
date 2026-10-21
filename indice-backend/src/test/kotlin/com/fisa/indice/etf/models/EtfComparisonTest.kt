package com.fisa.indice.etf.models

import com.fisa.indice.etf.exceptions.InsufficientComparisonDataException
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EtfComparisonTest {

    private val now = Instant.parse("2026-10-20T08:00:00Z")
    private val lastWeek = Instant.parse("2026-10-13T08:00:00Z")
    private val spy = Etf("SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", now)
    private val qqq = Etf("QQQ", "NASDAQ", "Invesco QQQ Trust", "USD", now)

    private fun price(date: String, close: String) = ClosingPrice(LocalDate.parse(date), BigDecimal(close))

    private fun prices(vararg prices: ClosingPrice, fetchedAt: Instant = now, stale: Boolean = false) =
        EtfPrices(ClosingPriceHistory(prices.toList()), fetchedAt, stale)

    private val noHistory = EtfPrices(null, null, stale = true)

    private val twoYears = prices(
        price("2024-10-18", "100"),
        price("2025-10-17", "110"),
        price("2026-04-01", "99"),
        price("2026-10-19", "121"),
    )

    private fun assertInsufficientData(expectedKey: String, etfAPrices: EtfPrices, etfBPrices: EtfPrices) {
        val exception = assertThrows<InsufficientComparisonDataException> { EtfComparison.between(spy, etfAPrices, qqq, etfBPrices) }
        assertEquals(expectedKey, exception.message)
    }

    @Test
    fun `should compare both etfs on their common period`() {
        // Given : l'ETF B commence un an plus tard que l'ETF A
        val etfBPrices = prices(price("2025-10-17", "50"), price("2026-04-01", "45"), price("2026-10-19", "60"), fetchedAt = lastWeek, stale = true)

        // When
        val comparison = EtfComparison.between(spy, twoYears, qqq, etfBPrices)

        // Then
        assertEquals(DateRange(LocalDate.parse("2025-10-17"), LocalDate.parse("2026-10-19")), comparison.commonPeriod)
        assertEquals(BigDecimal("0.1000"), comparison.etfA.performance.totalReturn)
        assertEquals(BigDecimal("0.2000"), comparison.etfB.performance.totalReturn)
        assertEquals(LocalDate.parse("2025-10-17"), comparison.etfA.rebasedPrices.first().date)
        assertEquals(BigDecimal("100.00"), comparison.etfA.rebasedPrices.first().value)
        assertEquals(LocalDate.parse("2026-10-19"), comparison.etfB.rebasedPrices.last().date)
    }

    @Test
    fun `should report freshness of each etf on its own side`() {
        // Given
        val etfBPrices = prices(price("2024-10-18", "50"), price("2026-10-19", "60"), fetchedAt = lastWeek, stale = true)

        // When
        val comparison = EtfComparison.between(spy, twoYears, qqq, etfBPrices)

        // Then
        assertEquals(spy, comparison.etfA.etf)
        assertEquals(now, comparison.etfA.fetchedAt)
        assertFalse(comparison.etfA.stale)
        assertEquals(qqq, comparison.etfB.etf)
        assertEquals(lastWeek, comparison.etfB.fetchedAt)
        assertTrue(comparison.etfB.stale)
    }

    @Test
    fun `should compute the correlation between both etfs`() {
        // Given : l'ETF B bouge exactement comme l'ETF A
        val etfBPrices = prices(price("2024-10-18", "200"), price("2025-10-17", "220"), price("2026-04-01", "198"), price("2026-10-19", "242"))

        // When
        val comparison = EtfComparison.between(spy, twoYears, qqq, etfBPrices)

        // Then
        assertEquals(BigDecimal("1.0000"), comparison.correlation)
    }

    @Test
    fun `should blame etf A when it has no history`() {
        assertInsufficientData(InsufficientComparisonDataException.ETF_A, noHistory, twoYears)
    }

    @Test
    fun `should blame etf B when its history covers less than one year`() {
        val etfBPrices = prices(price("2025-10-20", "50"), price("2026-10-19", "60"))

        assertInsufficientData(InsufficientComparisonDataException.ETF_B, twoYears, etfBPrices)
    }

    @Test
    fun `should blame both etfs when neither has enough data`() {
        val etfBPrices = prices(price("2026-01-02", "50"), price("2026-10-19", "60"))

        assertInsufficientData(InsufficientComparisonDataException.BOTH_ETFS, noHistory, etfBPrices)
    }

    @Test
    fun `should measure the year of history up to the oldest last close`() {
        // Given : l'ETF B s'arrête en avril 2026, son historique couvre un an jusqu'à cette date
        val etfBPrices = prices(price("2025-04-01", "50"), price("2025-10-17", "55"), price("2026-04-01", "60"))

        // When
        val comparison = EtfComparison.between(spy, twoYears, qqq, etfBPrices)

        // Then
        assertEquals(DateRange(LocalDate.parse("2025-10-17"), LocalDate.parse("2026-04-01")), comparison.commonPeriod)
    }

    @Test
    fun `should blame both etfs when their histories share no date`() {
        val etfBPrices = prices(price("2024-10-17", "50"), price("2025-10-16", "55"), price("2026-10-20", "60"))

        assertInsufficientData(InsufficientComparisonDataException.BOTH_ETFS, twoYears, etfBPrices)
    }
}

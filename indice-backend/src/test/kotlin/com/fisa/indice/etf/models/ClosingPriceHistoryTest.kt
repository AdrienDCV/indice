package com.fisa.indice.etf.models

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.math.BigDecimal
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ClosingPriceHistoryTest {

    private fun price(date: String, close: String) = ClosingPrice(LocalDate.parse(date), BigDecimal(close))

    private fun history(vararg prices: ClosingPrice) = ClosingPriceHistory(prices.toList())

    private fun assertDecimal(expected: String, actual: BigDecimal?) = assertEquals(BigDecimal(expected), actual)

    @Test
    fun `should reject an empty history`() {
        assertThrows<IllegalArgumentException> { ClosingPriceHistory(emptyList()) }
    }

    @Test
    fun `should reject prices that are not sorted by strictly increasing date`() {
        assertThrows<IllegalArgumentException> { history(price("2026-10-19", "100"), price("2026-10-16", "100")) }
        assertThrows<IllegalArgumentException> { history(price("2026-10-19", "100"), price("2026-10-19", "101")) }
    }

    @Test
    fun `should reject a non positive closing price`() {
        assertThrows<IllegalArgumentException> { price("2026-10-19", "0") }
    }

    @Test
    fun `should sort and deduplicate prices when built from an unsorted list`() {
        // When
        val history = ClosingPriceHistory.fromUnsorted(
            listOf(price("2026-10-19", "102"), price("2026-10-15", "100"), price("2026-10-19", "102"))
        )

        // Then
        assertEquals(listOf(price("2026-10-15", "100"), price("2026-10-19", "102")), history.prices)
    }

    @Test
    fun `should expose last close and history start date`() {
        val history = history(price("2021-10-12", "100"), price("2026-10-19", "150"))

        assertEquals(price("2026-10-19", "150"), history.lastClose())
        assertEquals(LocalDate.parse("2021-10-12"), history.historyStartDate())
    }

    @Test
    fun `should compute return over one year`() {
        val history = history(price("2025-10-17", "100"), price("2026-04-01", "130"), price("2026-10-17", "110"))

        assertDecimal("0.1000", history.returnOver(1))
    }

    @Test
    fun `should use the last close before the reference date when it falls on a closed market day`() {
        // Given : la date de référence, 2025-10-19, est un dimanche
        val history = history(price("2025-10-16", "100"), price("2025-10-20", "105"), price("2026-10-19", "120"))

        // When / Then
        assertDecimal("0.2000", history.returnOver(1))
    }

    @Test
    fun `should not compute a return when history is too short`() {
        val history = history(price("2025-12-01", "100"), price("2026-10-19", "120"))

        assertNull(history.returnOver(1))
        assertNull(history.annualizedReturnOver(5))
    }

    @Test
    fun `should compute annualized return over five years`() {
        // Given : le cours double en 5 ans
        val history = history(price("2021-10-19", "100"), price("2026-10-19", "200"))

        // When / Then : 2^(1/5) - 1
        assertDecimal("0.1487", history.annualizedReturnOver(5))
    }

    @Test
    fun `should compute annualized volatility from daily returns`() {
        // Given : rendements de +10 % puis -10 %, écart-type sqrt(0.02)
        val history = history(price("2025-10-19", "100"), price("2026-04-01", "110"), price("2026-10-19", "99"))

        // When / Then : sqrt(0.02) * sqrt(252) = sqrt(5.04)
        assertDecimal("2.2450", history.volatilityOver(1))
    }

    @Test
    fun `should have a zero volatility when prices never move`() {
        val history = history(price("2025-10-19", "100"), price("2026-04-01", "100"), price("2026-10-19", "100"))

        assertDecimal("0.0000", history.volatilityOver(1))
    }

    @Test
    fun `should not compute volatility when history is too short`() {
        assertNull(history(price("2026-01-02", "100"), price("2026-10-19", "110")).volatilityOver(1))
    }

    @Test
    fun `should compute max drawdown with its peak and trough dates`() {
        // Given
        val history = history(
            price("2021-10-19", "100"),
            price("2022-01-03", "120"),
            price("2022-10-12", "90"),
            price("2025-06-02", "130"),
            price("2026-10-19", "117"),
        )

        // When
        val drawdown = history.maxDrawdownOver(5)

        // Then
        assertEquals(Drawdown(BigDecimal("-0.2500"), LocalDate.parse("2022-01-03"), LocalDate.parse("2022-10-12")), drawdown)
    }

    @Test
    fun `should have a zero drawdown when prices only rise`() {
        val history = history(price("2021-10-19", "100"), price("2024-01-02", "120"), price("2026-10-19", "150"))

        assertDecimal("0.0000", history.maxDrawdownOver(5)?.value)
    }

    @Test
    fun `should not compute max drawdown when history is too short`() {
        assertNull(history(price("2023-01-02", "100"), price("2026-10-19", "150")).maxDrawdownOver(5))
    }

    @Test
    fun `should compute fifty two week range and position of last close`() {
        // Given
        val history = history(
            price("2024-06-03", "60"),
            price("2025-10-19", "100"),
            price("2026-02-02", "80"),
            price("2026-06-01", "120"),
            price("2026-10-19", "110"),
        )

        // When
        val range = history.fiftyTwoWeekRange()

        // Then : 60 est hors de la fenêtre d'un an
        assertEquals(PriceRange(BigDecimal("80.00"), BigDecimal("120.00"), BigDecimal("0.7500")), range)
    }

    @Test
    fun `should place last close in the middle when the range is flat`() {
        val history = history(price("2025-10-19", "100"), price("2026-10-19", "100"))

        assertDecimal("0.5000", history.fiftyTwoWeekRange()?.position)
    }

    @Test
    fun `should not compute fifty two week range when history is too short`() {
        assertNull(history(price("2026-01-02", "100"), price("2026-10-19", "110")).fiftyTwoWeekRange())
    }

    @Test
    fun `should round prices to two decimals and rates to four decimals in market data`() {
        // Given
        val history = history(price("2025-10-17", "100.123456"), price("2026-10-19", "110.987654"))

        // When
        val marketData = history.marketData()

        // Then
        assertEquals(BigDecimal("110.99"), marketData.lastClose.adjustedClose)
        assertEquals(BigDecimal("0.1085"), marketData.returnOneYear)
        assertEquals(BigDecimal("100.12"), marketData.fiftyTwoWeekRange?.low)
    }

    @Test
    fun `should gather all indicators in market data`() {
        // Given
        val history = history(price("2021-10-19", "100"), price("2023-10-19", "150"), price("2025-10-17", "160"), price("2026-10-19", "200"))

        // When
        val marketData = history.marketData()

        // Then
        assertEquals(price("2026-10-19", "200.00"), marketData.lastClose)
        assertEquals(LocalDate.parse("2021-10-19"), marketData.historyStartDate)
        assertDecimal("0.2500", marketData.returnOneYear)
        assertDecimal("0.3333", marketData.returnThreeYears)
        assertDecimal("1.0000", marketData.returnFiveYears)
        assertDecimal("0.1487", marketData.annualizedReturnFiveYears)
    }

    @Test
    fun `should be stale when closing prices were never fetched`() {
        assertTrue(ClosingPriceHistory.isStale(null, Instant.parse("2026-10-20T08:00:00Z")))
    }

    @Test
    fun `should not be stale when fetched less than or exactly one day ago`() {
        val now = Instant.parse("2026-10-20T08:00:00Z")

        assertFalse(ClosingPriceHistory.isStale(now.minus(Duration.ofHours(23)), now))
        assertFalse(ClosingPriceHistory.isStale(now.minus(Duration.ofDays(1)), now))
    }

    @Test
    fun `should be stale when fetched more than one day ago`() {
        val now = Instant.parse("2026-10-20T08:00:00Z")

        assertTrue(ClosingPriceHistory.isStale(now.minus(Duration.ofDays(1).plusSeconds(1)), now))
    }
}

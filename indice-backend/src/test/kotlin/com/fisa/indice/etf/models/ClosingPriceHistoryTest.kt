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

    @Test
    fun `should keep only the dates both histories have in common`() {
        // Given
        val first = history(price("2026-10-12", "100"), price("2026-10-13", "101"), price("2026-10-14", "102"), price("2026-10-15", "103"))
        val second = history(price("2026-10-13", "50"), price("2026-10-15", "52"), price("2026-10-16", "53"))

        // When
        val common = first.commonPeriodWith(second)

        // Then
        assertEquals(history(price("2026-10-13", "101"), price("2026-10-15", "103")), common?.first)
        assertEquals(history(price("2026-10-13", "50"), price("2026-10-15", "52")), common?.second)
    }

    @Test
    fun `should have no common period when histories share no date`() {
        val first = history(price("2026-10-12", "100"), price("2026-10-13", "101"))
        val second = history(price("2026-10-14", "50"), price("2026-10-15", "52"))

        assertNull(first.commonPeriodWith(second))
    }

    @Test
    fun `should cover one year only when a close exists at least one year before the date`() {
        val history = history(price("2025-10-19", "100"), price("2026-10-19", "110"))

        assertTrue(history.coversOneYearUntil(LocalDate.parse("2026-10-19")))
        assertTrue(history.coversOneYearUntil(LocalDate.parse("2026-10-20")))
        assertFalse(history.coversOneYearUntil(LocalDate.parse("2026-10-18")))
    }

    @Test
    fun `should compute total return over the whole history`() {
        val history = history(price("2025-10-17", "100"), price("2026-04-01", "130"), price("2026-10-19", "125"))

        assertDecimal("0.2500", history.totalReturn())
    }

    @Test
    fun `should annualize the return over five years like the detail sheet`() {
        // Given : le cours double en 5 ans (1 826 jours)
        val history = history(price("2021-10-19", "100"), price("2026-10-19", "200"))

        // When / Then : 2^(365,25 / 1826) - 1
        assertDecimal("0.1487", history.annualizedReturn())
    }

    @Test
    fun `should annualize the return over a non whole number of years`() {
        // Given : +21 % en 548 jours
        val history = history(price("2025-04-19", "100"), price("2026-10-19", "121"))

        // When / Then : 1,21^(365,25 / 548) - 1
        assertDecimal("0.1355", history.annualizedReturn())
    }

    @Test
    fun `should not annualize a return over less than one year`() {
        val history = history(price("2025-10-20", "100"), price("2026-10-19", "120"))

        assertNull(history.annualizedReturn())
        assertNull(history.returnToRiskRatio())
    }

    @Test
    fun `should compute the whole history volatility`() {
        // Given : rendements de +10 % puis -10 %, écart-type sqrt(0.02)
        val history = history(price("2025-10-19", "100"), price("2026-04-01", "110"), price("2026-10-19", "99"))

        // When / Then
        assertDecimal("2.2450", history.volatility())
    }

    @Test
    fun `should compute max drawdown over the whole history`() {
        val history = history(price("2025-10-19", "100"), price("2026-01-05", "120"), price("2026-06-01", "90"), price("2026-10-19", "130"))

        assertEquals(
            Drawdown(BigDecimal("-0.2500"), LocalDate.parse("2026-01-05"), LocalDate.parse("2026-06-01")),
            history.maxDrawdown(),
        )
    }

    @Test
    fun `should divide annualized return by volatility for the return to risk ratio`() {
        // Given : +21 % en 548 jours, rendements +10 %, -10 %, +22,2 %
        val history = history(price("2025-04-19", "100"), price("2025-09-01", "110"), price("2026-02-02", "99"), price("2026-10-19", "121"))

        // When / Then : 0,13548 / 2,58228
        assertDecimal("0.0525", history.returnToRiskRatio())
    }

    @Test
    fun `should not compute the return to risk ratio when volatility is zero`() {
        val history = history(price("2025-10-19", "100"), price("2026-04-01", "100"), price("2026-10-19", "100"))

        assertNull(history.returnToRiskRatio())
    }

    @Test
    fun `should gather all indicators in performance`() {
        // Given
        val history = history(price("2025-04-19", "100"), price("2025-09-01", "110"), price("2026-02-02", "99"), price("2026-10-19", "121"))

        // When
        val performance = history.performance()

        // Then
        assertDecimal("0.2100", performance.totalReturn)
        assertDecimal("0.1355", performance.annualizedReturn)
        assertDecimal("2.5823", performance.volatility)
        assertDecimal("0.0525", performance.returnToRiskRatio)
        assertEquals(Drawdown(BigDecimal("-0.1000"), LocalDate.parse("2025-09-01"), LocalDate.parse("2026-02-02")), performance.maxDrawdown)
    }

    @Test
    fun `should rebase every close to 100 from the first close`() {
        // Given
        val history = history(
            price("2026-01-05", "50"),
            price("2026-01-06", "55"),
            price("2026-01-07", "45"),
            price("2026-01-08", "75.123"),
        )

        // When / Then : une valeur par jour de bourse, arrondie à 2 décimales
        assertEquals(
            listOf(
                RebasedPrice(LocalDate.parse("2026-01-05"), BigDecimal("100.00")),
                RebasedPrice(LocalDate.parse("2026-01-06"), BigDecimal("110.00")),
                RebasedPrice(LocalDate.parse("2026-01-07"), BigDecimal("90.00")),
                RebasedPrice(LocalDate.parse("2026-01-08"), BigDecimal("150.25")),
            ),
            history.rebased(),
        )
    }

    @Test
    fun `should show the max drawdown trough on the rebased curve`() {
        // Given : le creux tombe un mercredi, au milieu de la semaine
        val history = history(price("2026-01-05", "100"), price("2026-01-07", "80"), price("2026-01-09", "95"))

        // When
        val lowestPoint = history.rebased().minBy { it.value }

        // Then
        assertEquals(history.maxDrawdown().troughDate, lowestPoint.date)
    }

    @Test
    fun `should have a correlation of 1 when daily returns are proportional`() {
        // Given : le second ETF bouge exactement comme le premier, à un prix double
        val first = history(price("2026-10-12", "100"), price("2026-10-13", "110"), price("2026-10-14", "99"), price("2026-10-15", "105"))
        val second = history(price("2026-10-12", "200"), price("2026-10-13", "220"), price("2026-10-14", "198"), price("2026-10-15", "210"))

        assertDecimal("1.0000", first.correlationWith(second))
    }

    @Test
    fun `should have a correlation of -1 when daily returns are opposite`() {
        // Given : +10 %, -10 %, +10 % contre -10 %, +10 %, -10 %
        val first = history(price("2026-10-12", "100"), price("2026-10-13", "110"), price("2026-10-14", "99"), price("2026-10-15", "108.9"))
        val second = history(price("2026-10-12", "100"), price("2026-10-13", "90"), price("2026-10-14", "99"), price("2026-10-15", "89.1"))

        assertDecimal("-1.0000", first.correlationWith(second))
    }

    @Test
    fun `should not compute correlation when one etf never moves`() {
        val first = history(price("2026-10-12", "100"), price("2026-10-13", "110"), price("2026-10-14", "99"))
        val second = history(price("2026-10-12", "50"), price("2026-10-13", "50"), price("2026-10-14", "50"))

        assertNull(first.correlationWith(second))
    }

    @Test
    fun `should not compute correlation with less than two daily returns`() {
        val first = history(price("2026-10-12", "100"), price("2026-10-13", "110"))
        val second = history(price("2026-10-12", "50"), price("2026-10-13", "55"))

        assertNull(first.correlationWith(second))
    }

    @Test
    fun `should refuse to correlate histories with different dates`() {
        val first = history(price("2026-10-12", "100"), price("2026-10-13", "110"), price("2026-10-14", "99"))
        val second = history(price("2026-10-12", "50"), price("2026-10-14", "55"), price("2026-10-15", "60"))

        assertThrows<IllegalArgumentException> { first.correlationWith(second) }
    }
}

package com.fisa.indice.etf.models

import java.math.BigDecimal
import java.math.MathContext
import java.math.RoundingMode
import java.time.Duration
import java.time.Instant
import java.time.LocalDate

data class ClosingPriceHistory(val prices: List<ClosingPrice>) {
    init {
        require(prices.isNotEmpty()) { "A closing price history cannot be empty" }
        require(prices.zipWithNext().all { (previous, next) -> previous.date < next.date }) {
            "Closing prices must be sorted by strictly increasing date"
        }
    }

    fun lastClose(): ClosingPrice = prices.last()

    fun historyStartDate(): LocalDate = prices.first().date

    fun returnOver(years: Long): BigDecimal? {
        val reference = referenceCloseOver(years) ?: return null
        return (lastClose().adjustedClose.divide(reference.adjustedClose, MATH_CONTEXT) - BigDecimal.ONE).rounded()
    }

    fun annualizedReturnOver(years: Long): BigDecimal? {
        val reference = referenceCloseOver(years) ?: return null
        val growth = lastClose().adjustedClose.divide(reference.adjustedClose, MATH_CONTEXT)
        return (BigDecimal(Math.pow(growth.toDouble(), 1.0 / years)) - BigDecimal.ONE).rounded()
    }

    fun volatilityOver(years: Long): BigDecimal? {
        val dailyReturns = windowOver(years)?.zipWithNext { previous, next ->
            next.adjustedClose.divide(previous.adjustedClose, MATH_CONTEXT) - BigDecimal.ONE
        } ?: return null
        if (dailyReturns.size < 2) return null
        val count = BigDecimal(dailyReturns.size)
        val mean = dailyReturns.fold(BigDecimal.ZERO, BigDecimal::add).divide(count, MATH_CONTEXT)
        val variance = dailyReturns
            .fold(BigDecimal.ZERO) { sum, dailyReturn -> sum + (dailyReturn - mean).pow(2, MATH_CONTEXT) }
            .divide(count - BigDecimal.ONE, MATH_CONTEXT)
        return (variance.sqrt(MATH_CONTEXT) * TRADING_DAYS_PER_YEAR.sqrt(MATH_CONTEXT)).rounded()
    }

    fun maxDrawdownOver(years: Long): Drawdown? {
        val window = windowOver(years) ?: return null
        var peak = window.first()
        var worst = Drawdown(BigDecimal.ZERO, peak.date, peak.date)
        window.forEach { price ->
            if (price.adjustedClose > peak.adjustedClose) peak = price
            val drawdown = price.adjustedClose.divide(peak.adjustedClose, MATH_CONTEXT) - BigDecimal.ONE
            if (drawdown < worst.value) worst = Drawdown(drawdown, peak.date, price.date)
        }
        return worst.copy(value = worst.value.rounded())
    }

    fun fiftyTwoWeekRange(): PriceRange? {
        val closes = windowOver(1)?.map { it.adjustedClose } ?: return null
        val low = closes.min()
        val high = closes.max()
        val position = if (high.compareTo(low) == 0) MIDDLE_POSITION
        else (lastClose().adjustedClose - low).divide(high - low, MATH_CONTEXT)
        return PriceRange(low.roundedPrice(), high.roundedPrice(), position.rounded())
    }

    fun marketData(): MarketData = MarketData(
        lastClose = lastClose().let { it.copy(adjustedClose = it.adjustedClose.roundedPrice()) },
        historyStartDate = historyStartDate(),
        returnOneYear = returnOver(1),
        returnThreeYears = returnOver(3),
        returnFiveYears = returnOver(5),
        annualizedReturnFiveYears = annualizedReturnOver(5),
        volatilityOneYear = volatilityOver(1),
        maxDrawdownFiveYears = maxDrawdownOver(5),
        fiftyTwoWeekRange = fiftyTwoWeekRange(),
    )

    private fun referenceCloseOver(years: Long): ClosingPrice? {
        val referenceDate = lastClose().date.minusYears(years)
        return prices.lastOrNull { it.date <= referenceDate }
    }

    private fun windowOver(years: Long): List<ClosingPrice>? {
        val reference = referenceCloseOver(years) ?: return null
        return prices.filter { it.date >= reference.date }
    }

    private fun BigDecimal.rounded(): BigDecimal = setScale(RATE_SCALE, RoundingMode.HALF_EVEN)

    private fun BigDecimal.roundedPrice(): BigDecimal = setScale(PRICE_SCALE, RoundingMode.HALF_EVEN)

    companion object {
        val TTL: Duration = Duration.ofDays(1)

        private val MATH_CONTEXT = MathContext.DECIMAL64
        private val TRADING_DAYS_PER_YEAR = BigDecimal(252)
        private val MIDDLE_POSITION = BigDecimal("0.5")
        private const val RATE_SCALE = 4
        private const val PRICE_SCALE = 2

        fun fromUnsorted(prices: List<ClosingPrice>): ClosingPriceHistory =
            ClosingPriceHistory(prices.distinctBy { it.date }.sortedBy { it.date })

        fun isStale(fetchedAt: Instant?, now: Instant): Boolean =
            fetchedAt == null || fetchedAt.plus(TTL).isBefore(now)
    }
}

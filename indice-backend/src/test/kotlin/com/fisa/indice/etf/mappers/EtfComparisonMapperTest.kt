package com.fisa.indice.etf.mappers

import com.fisa.indice.etf.dtos.responses.ComparedEtfResponseDto
import com.fisa.indice.etf.dtos.responses.DateRangeResponseDto
import com.fisa.indice.etf.dtos.responses.EtfComparisonResponseDto
import com.fisa.indice.etf.dtos.responses.MaxDrawdownResponseDto
import com.fisa.indice.etf.dtos.responses.PerformanceResponseDto
import com.fisa.indice.etf.dtos.responses.PricePointResponseDto
import com.fisa.indice.etf.models.ComparedEtf
import com.fisa.indice.etf.models.DateRange
import com.fisa.indice.etf.models.Drawdown
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.EtfComparison
import com.fisa.indice.etf.models.Performance
import com.fisa.indice.etf.models.PricePoint
import org.junit.jupiter.api.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import kotlin.test.assertEquals

class EtfComparisonMapperTest {

    private val now = Instant.parse("2026-10-20T08:00:00Z")
    private val start = LocalDate.parse("2021-10-20")
    private val end = LocalDate.parse("2026-10-19")
    private val peak = LocalDate.parse("2022-01-03")
    private val trough = LocalDate.parse("2022-10-12")

    private fun compared(etf: Etf, fetchedAt: Instant?, stale: Boolean) = ComparedEtf(
        etf = etf,
        performance = Performance(
            totalReturn = BigDecimal("0.8123"),
            annualizedReturn = BigDecimal("0.1263"),
            volatility = BigDecimal("0.0000"),
            returnToRiskRatio = null,
            maxDrawdown = Drawdown(BigDecimal("-0.2450"), peak, trough),
        ),
        pricePoints = listOf(PricePoint(start, BigDecimal("450.00"), BigDecimal("0.0000")), PricePoint(end, BigDecimal("815.54"), BigDecimal("0.8123"))),
        fetchedAt = fetchedAt,
        stale = stale,
    )

    private fun expected(ticker: String, exchange: String, name: String, fetchedAt: Instant?, stale: Boolean) = ComparedEtfResponseDto(
        ticker = ticker,
        exchange = exchange,
        name = name,
        currency = "USD",
        fetchedAt = fetchedAt,
        stale = stale,
        performance = PerformanceResponseDto(
            totalReturn = BigDecimal("0.8123"),
            annualizedReturn = BigDecimal("0.1263"),
            volatility = BigDecimal("0.0000"),
            returnToRiskRatio = null,
            maxDrawdown = MaxDrawdownResponseDto(BigDecimal("-0.2450"), peak, trough),
        ),
        pricePoints = listOf(PricePointResponseDto(start, BigDecimal("450.00"), BigDecimal("0.0000")), PricePointResponseDto(end, BigDecimal("815.54"), BigDecimal("0.8123"))),
    )

    @Test
    fun `should map a comparison with null ratio and correlation`() {
        // Given
        val comparison = EtfComparison(
            etfA = compared(Etf("SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", now), now, stale = false),
            etfB = compared(Etf("QQQ", "NASDAQ", "Invesco QQQ Trust", "USD", now), null, stale = true),
            commonPeriod = DateRange(start, end),
            correlation = null,
        )

        // When
        val dto = comparison.toDto()

        // Then
        assertEquals(
            EtfComparisonResponseDto(
                commonPeriod = DateRangeResponseDto(start, end),
                correlation = null,
                etfA = expected("SPY", "NYSE", "SPDR S&P 500 ETF Trust", now, stale = false),
                etfB = expected("QQQ", "NASDAQ", "Invesco QQQ Trust", null, stale = true),
            ),
            dto,
        )
    }
}

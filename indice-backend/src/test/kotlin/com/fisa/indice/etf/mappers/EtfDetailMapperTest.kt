package com.fisa.indice.etf.mappers

import com.fisa.indice.etf.dtos.responses.EtfDetailResponseDto
import com.fisa.indice.etf.dtos.responses.MarketDataResponseDto
import com.fisa.indice.etf.dtos.responses.MaxDrawdownResponseDto
import com.fisa.indice.etf.dtos.responses.PricePointResponseDto
import com.fisa.indice.etf.dtos.responses.PriceRangeResponseDto
import com.fisa.indice.etf.dtos.responses.ReturnsResponseDto
import com.fisa.indice.etf.models.ClosingPrice
import com.fisa.indice.etf.models.Drawdown
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.EtfDetail
import com.fisa.indice.etf.models.MarketData
import com.fisa.indice.etf.models.PricePoint
import com.fisa.indice.etf.models.PriceRange
import org.junit.jupiter.api.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import kotlin.test.assertEquals

class EtfDetailMapperTest {

    private val now = Instant.parse("2026-10-20T08:00:00Z")
    private val etf = Etf("SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", now)
    private val lastCloseDate = LocalDate.parse("2026-10-19")
    private val startDate = LocalDate.parse("2023-03-12")

    @Test
    fun `should map etf detail with market data and null indicators`() {
        // Given
        val marketData = MarketData(
            lastClose = ClosingPrice(lastCloseDate, BigDecimal("766.48")),
            historyStartDate = startDate,
            returnOneYear = BigDecimal("0.142"),
            returnThreeYears = BigDecimal("0.51"),
            returnFiveYears = null,
            annualizedReturnFiveYears = null,
            volatilityOneYear = BigDecimal("0.161"),
            maxDrawdownFiveYears = null,
            fiftyTwoWeekRange = PriceRange(BigDecimal("629.28"), BigDecimal("781.62"), BigDecimal("0.9")),
            pricePoints = listOf(
                PricePoint(startDate, BigDecimal("450.00"), BigDecimal("0.0000")),
                PricePoint(lastCloseDate, BigDecimal("766.48"), BigDecimal("0.7033")),
            ),
        )

        // When
        val dto = EtfDetail(etf, marketData, now, stale = false).toDto()

        // Then
        assertEquals(
            EtfDetailResponseDto(
                ticker = "SPY",
                exchange = "NYSE",
                name = "SPDR S&P 500 ETF Trust",
                currency = "USD",
                marketData = MarketDataResponseDto(
                    lastClose = BigDecimal("766.48"),
                    lastCloseDate = lastCloseDate,
                    historyStartDate = startDate,
                    returns = ReturnsResponseDto(BigDecimal("0.142"), BigDecimal("0.51"), null, null),
                    volatilityOneYear = BigDecimal("0.161"),
                    maxDrawdown = null,
                    fiftyTwoWeekRange = PriceRangeResponseDto(BigDecimal("629.28"), BigDecimal("781.62"), BigDecimal("0.9")),
                    pricePoints = listOf(
                        PricePointResponseDto(startDate, BigDecimal("450.00"), BigDecimal("0.0000")),
                        PricePointResponseDto(lastCloseDate, BigDecimal("766.48"), BigDecimal("0.7033")),
                    ),
                ),
                fetchedAt = now,
                stale = false,
                favourite = false,
            ),
            dto,
        )
    }

    @Test
    fun `should map max drawdown`() {
        val drawdown = Drawdown(BigDecimal("-0.245"), LocalDate.parse("2022-01-03"), LocalDate.parse("2022-10-12"))

        assertEquals(MaxDrawdownResponseDto(BigDecimal("-0.245"), LocalDate.parse("2022-01-03"), LocalDate.parse("2022-10-12")), drawdown.toDto())
    }

    @Test
    fun `should map etf detail without market data`() {
        val dto = EtfDetail(etf, marketData = null, closingPricesFetchedAt = null, stale = true).toDto()

        assertEquals(null, dto.marketData)
        assertEquals(null, dto.fetchedAt)
        assertEquals(true, dto.stale)
    }

    @Test
    fun `should map the favourite flag of the etf`() {
        val dto = EtfDetail(etf.copy(favourite = true), marketData = null, closingPricesFetchedAt = null, stale = true).toDto()

        assertEquals(true, dto.favourite)
    }
}

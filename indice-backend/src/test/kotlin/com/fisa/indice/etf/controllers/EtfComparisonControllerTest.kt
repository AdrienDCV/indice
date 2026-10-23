package com.fisa.indice.etf.controllers

import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.exceptions.InsufficientComparisonDataException
import com.fisa.indice.etf.exceptions.InvalidTickerException
import com.fisa.indice.etf.exceptions.SameEtfComparisonException
import com.fisa.indice.etf.models.ComparedEtf
import com.fisa.indice.etf.models.DateRange
import com.fisa.indice.etf.models.Drawdown
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.EtfComparison
import com.fisa.indice.etf.models.Performance
import com.fisa.indice.etf.models.PricePoint
import com.fisa.indice.etf.services.EtfComparisonService
import io.mockk.every
import io.mockk.mockk
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest
import org.springframework.context.annotation.Bean
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate

@WebMvcTest(EtfComparisonController::class)
class EtfComparisonControllerTest(
    @Autowired private val mockMvc: MockMvc,
    @Autowired private val etfComparisonService: EtfComparisonService,
) {

    @TestConfiguration
    class MockConfig {
        @Bean
        fun etfComparisonService(): EtfComparisonService = mockk()
    }

    private val fetchedAt = Instant.parse("2026-10-20T08:00:00Z")
    private val start = LocalDate.parse("2021-10-20")
    private val end = LocalDate.parse("2026-10-19")

    private fun compared(etf: Etf, stale: Boolean) = ComparedEtf(
        etf = etf,
        performance = Performance(
            totalReturn = BigDecimal("0.8123"),
            annualizedReturn = BigDecimal("0.1263"),
            volatility = BigDecimal("0.1712"),
            returnToRiskRatio = BigDecimal("0.7377"),
            maxDrawdown = Drawdown(BigDecimal("-0.2450"), LocalDate.parse("2022-01-03"), LocalDate.parse("2022-10-12")),
        ),
        pricePoints = listOf(PricePoint(start, BigDecimal("450.00"), BigDecimal("0.0000")), PricePoint(end, BigDecimal("815.54"), BigDecimal("0.8123"))),
        fetchedAt = fetchedAt,
        stale = stale,
    )

    @Test
    fun `should return the comparison of both etfs`() {
        // Given
        every { etfComparisonService.compare("spy", "qqq") } returns EtfComparison(
            etfA = compared(Etf("SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", fetchedAt), stale = false),
            etfB = compared(Etf("QQQ", "NASDAQ", "Invesco QQQ Trust", "USD", fetchedAt), stale = true),
            commonPeriod = DateRange(start, end),
            correlation = BigDecimal("0.9312"),
        )

        // When / Then
        mockMvc.get("/etfs/compare?etfA=spy&etfB=qqq").andExpect {
            status { isOk() }
            jsonPath("$.commonPeriod.startDate") { value("2021-10-20") }
            jsonPath("$.commonPeriod.endDate") { value("2026-10-19") }
            jsonPath("$.correlation") { value(0.9312) }
            jsonPath("$.etfA.ticker") { value("SPY") }
            jsonPath("$.etfA.exchange") { value("NYSE") }
            jsonPath("$.etfA.name") { value("SPDR S&P 500 ETF Trust") }
            jsonPath("$.etfA.currency") { value("USD") }
            jsonPath("$.etfA.fetchedAt") { value("2026-10-20T08:00:00Z") }
            jsonPath("$.etfA.stale") { value(false) }
            jsonPath("$.etfA.performance.totalReturn") { value(0.8123) }
            jsonPath("$.etfA.performance.annualizedReturn") { value(0.1263) }
            jsonPath("$.etfA.performance.volatility") { value(0.1712) }
            jsonPath("$.etfA.performance.returnToRiskRatio") { value(0.7377) }
            jsonPath("$.etfA.performance.maxDrawdown.value") { value(-0.245) }
            jsonPath("$.etfA.performance.maxDrawdown.peakDate") { value("2022-01-03") }
            jsonPath("$.etfA.performance.maxDrawdown.troughDate") { value("2022-10-12") }
            jsonPath("$.etfA.pricePoints[0].date") { value("2021-10-20") }
            jsonPath("$.etfA.pricePoints[0].close") { value(450.0) }
            jsonPath("$.etfA.pricePoints[0].changeSinceStart") { value(0.0) }
            jsonPath("$.etfA.pricePoints[1].close") { value(815.54) }
            jsonPath("$.etfA.pricePoints[1].changeSinceStart") { value(0.8123) }
            jsonPath("$.etfB.ticker") { value("QQQ") }
            jsonPath("$.etfB.stale") { value(true) }
            jsonPath("$.winner") { doesNotExist() }
        }
    }

    @Test
    fun `should return bad request when a parameter is missing`() {
        mockMvc.get("/etfs/compare?etfA=SPY").andExpect {
            status { isBadRequest() }
            jsonPath("$[0].message") { value("error.request.missing-parameter") }
        }
    }

    @Test
    fun `should return bad request when a ticker is invalid`() {
        every { etfComparisonService.compare("SPY", "QQ Q") } throws InvalidTickerException()

        mockMvc.get("/etfs/compare?etfA=SPY&etfB=QQ Q").andExpect {
            status { isBadRequest() }
            jsonPath("$[0].message") { value("error.etfs.invalid-ticker") }
        }
    }

    @Test
    fun `should return not found when an etf is not in the catalog`() {
        every { etfComparisonService.compare("SPY", "ARKK") } throws EtfNotFoundException()

        mockMvc.get("/etfs/compare?etfA=SPY&etfB=ARKK").andExpect {
            status { isNotFound() }
            jsonPath("$[0].message") { value("error.etfs.etf-not-found") }
        }
    }

    @Test
    fun `should return bad request when both sides are the same etf`() {
        every { etfComparisonService.compare("SPY", "spy") } throws SameEtfComparisonException()

        mockMvc.get("/etfs/compare?etfA=SPY&etfB=spy").andExpect {
            status { isBadRequest() }
            jsonPath("$[0].message") { value("error.etfs.same-etf-comparison") }
        }
    }

    @Test
    fun `should return unprocessable content when an etf lacks data`() {
        every { etfComparisonService.compare("SPY", "QQQ") } throws
            InsufficientComparisonDataException(InsufficientComparisonDataException.ETF_B)

        mockMvc.get("/etfs/compare?etfA=SPY&etfB=QQQ").andExpect {
            status { isUnprocessableContent() }
            jsonPath("$[0].error") { value("Unprocessable Content") }
            jsonPath("$[0].message") { value("error.etfs.etf-b-insufficient-data") }
        }
    }
}

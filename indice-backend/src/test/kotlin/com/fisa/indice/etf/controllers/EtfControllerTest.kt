package com.fisa.indice.etf.controllers

import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.exceptions.InvalidTickerException
import com.fisa.indice.etf.models.ClosingPrice
import com.fisa.indice.etf.models.Drawdown
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.EtfDetail
import com.fisa.indice.etf.models.MarketData
import com.fisa.indice.etf.models.PricePoint
import com.fisa.indice.etf.models.PriceRange
import com.fisa.indice.etf.models.RetrievedEtfCatalog
import com.fisa.indice.etf.services.EtfDetailService
import com.fisa.indice.etf.services.EtfService
import io.mockk.CapturingSlot
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest
import org.springframework.context.annotation.Bean
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.Pageable
import org.springframework.data.domain.Sort
import io.mockk.justRun
import io.mockk.verify
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.put
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import kotlin.test.assertEquals

@WebMvcTest(EtfController::class)
class EtfControllerTest(
    @Autowired private val mockMvc: MockMvc,
    @Autowired private val etfService: EtfService,
    @Autowired private val etfDetailService: EtfDetailService,
) {

    @TestConfiguration
    class MockConfig {
        @Bean
        fun etfService(): EtfService = mockk()

        @Bean
        fun etfDetailService(): EtfDetailService = mockk()
    }

    private val fetchedAt = Instant.parse("2026-10-07T08:00:00Z")
    private val etf = Etf("SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", fetchedAt)

    private fun givenServiceReturnsOneEtf(): CapturingSlot<Pageable> {
        val pageable = slot<Pageable>()
        every { etfService.retrieveEtfs(capture(pageable), any(), any()) } answers {
            RetrievedEtfCatalog(PageImpl(listOf(etf), pageable.captured, 12), fetchedAt, stale = false)
        }
        return pageable
    }

    @Test
    fun `should return paginated etf catalog`() {
        // Given
        givenServiceReturnsOneEtf()

        // When / Then
        mockMvc.get("/etfs?page=1&size=5").andExpect {
            status { isOk() }
            jsonPath("$.etfs.content[0].ticker") { value("SPY") }
            jsonPath("$.etfs.content[0].exchange") { value("NYSE") }
            jsonPath("$.etfs.content[0].name") { value("SPDR S&P 500 ETF Trust") }
            jsonPath("$.etfs.content[0].isin") { doesNotExist() }
            jsonPath("$.etfs.content[0].currency") { value("USD") }
            jsonPath("$.etfs.content[0].favourite") { value(false) }
            jsonPath("$.etfs.page") { value(1) }
            jsonPath("$.etfs.size") { value(5) }
            jsonPath("$.etfs.totalElements") { value(12) }
            jsonPath("$.etfs.totalPages") { value(3) }
            jsonPath("$.fetchedAt") { value("2026-10-07T08:00:00Z") }
            jsonPath("$.stale") { value(false) }
        }
    }

    @Test
    fun `should request first page of 20 etfs sorted by name by default`() {
        // Given
        val pageable = givenServiceReturnsOneEtf()

        // When
        mockMvc.get("/etfs").andExpect { status { isOk() } }

        // Then
        assertEquals(0, pageable.captured.pageNumber)
        assertEquals(20, pageable.captured.pageSize)
        assertEquals(Sort.by("name"), pageable.captured.sort)
    }

    @Test
    fun `should return etf detail`() {
        // Given
        val marketData = MarketData(
            lastClose = ClosingPrice(LocalDate.parse("2026-10-19"), BigDecimal("766.48")),
            historyStartDate = LocalDate.parse("2021-10-13"),
            returnOneYear = BigDecimal("0.142"),
            returnThreeYears = BigDecimal("0.51"),
            returnFiveYears = BigDecimal("0.88"),
            annualizedReturnFiveYears = BigDecimal("0.135"),
            volatilityOneYear = BigDecimal("0.161"),
            maxDrawdownFiveYears = Drawdown(BigDecimal("-0.245"), LocalDate.parse("2022-01-03"), LocalDate.parse("2022-10-12")),
            fiftyTwoWeekRange = PriceRange(BigDecimal("629.28"), BigDecimal("781.62"), BigDecimal("0.9")),
            pricePoints = listOf(PricePoint(LocalDate.parse("2021-10-13"), BigDecimal("450.00"), BigDecimal("0.0000"))),
        )
        every { etfDetailService.retrieveEtf("spy") } returns EtfDetail(etf, marketData, fetchedAt, stale = false)

        // When / Then
        mockMvc.get("/etfs/spy").andExpect {
            status { isOk() }
            jsonPath("$.ticker") { value("SPY") }
            jsonPath("$.name") { value("SPDR S&P 500 ETF Trust") }
            jsonPath("$.currency") { value("USD") }
            jsonPath("$.marketData.lastClose") { value(766.48) }
            jsonPath("$.marketData.lastCloseDate") { value("2026-10-19") }
            jsonPath("$.marketData.historyStartDate") { value("2021-10-13") }
            jsonPath("$.marketData.returns.oneYear") { value(0.142) }
            jsonPath("$.marketData.returns.fiveYearsAnnualized") { value(0.135) }
            jsonPath("$.marketData.volatilityOneYear") { value(0.161) }
            jsonPath("$.marketData.maxDrawdown.value") { value(-0.245) }
            jsonPath("$.marketData.maxDrawdown.peakDate") { value("2022-01-03") }
            jsonPath("$.marketData.fiftyTwoWeekRange.position") { value(0.9) }
            jsonPath("$.marketData.pricePoints[0].date") { value("2021-10-13") }
            jsonPath("$.marketData.pricePoints[0].close") { value(450.00) }
            jsonPath("$.marketData.pricePoints[0].changeSinceStart") { value(0.0) }
            jsonPath("$.fetchedAt") { value("2026-10-07T08:00:00Z") }
            jsonPath("$.stale") { value(false) }
            jsonPath("$.favourite") { value(false) }
        }
    }

    @Test
    fun `should return null market data when no price is available`() {
        every { etfDetailService.retrieveEtf("SPY") } returns EtfDetail(etf, null, null, stale = true)

        mockMvc.get("/etfs/SPY").andExpect {
            status { isOk() }
            jsonPath("$.marketData") { value(null) }
            jsonPath("$.stale") { value(true) }
        }
    }

    @Test
    fun `should return bad request when ticker is invalid`() {
        every { etfDetailService.retrieveEtf("SPY$") } throws InvalidTickerException()

        mockMvc.get("/etfs/SPY$").andExpect {
            status { isBadRequest() }
            jsonPath("$[0].message") { value("error.etfs.invalid-ticker") }
        }
    }

    @Test
    fun `should return not found when etf is not in the catalog`() {
        every { etfDetailService.retrieveEtf("ARKK") } throws EtfNotFoundException()

        mockMvc.get("/etfs/ARKK").andExpect {
            status { isNotFound() }
            jsonPath("$[0].message") { value("error.etfs.etf-not-found") }
        }
    }

    @Test
    fun `should pass the search and the favourites filter to the service`() {
        // Given
        givenServiceReturnsOneEtf()

        // When
        mockMvc.get("/etfs?search=van&favourites=true").andExpect { status { isOk() } }

        // Then
        verify(exactly = 1) { etfService.retrieveEtfs(any(), "van", true) }
    }

    @Test
    fun `should not filter the catalog by default`() {
        // Given
        givenServiceReturnsOneEtf()

        // When
        mockMvc.get("/etfs").andExpect { status { isOk() } }

        // Then
        verify(exactly = 1) { etfService.retrieveEtfs(any(), null, false) }
    }

    @Test
    fun `should return created when an etf is pinned`() {
        every { etfService.addFavourite("SPY") } returns true

        mockMvc.put("/etfs/SPY/favourite").andExpect {
            status { isCreated() }
            content { string("") }
        }
    }

    @Test
    fun `should return ok when the etf was already a favourite`() {
        every { etfService.addFavourite("SPY") } returns false

        mockMvc.put("/etfs/SPY/favourite").andExpect {
            status { isOk() }
            content { string("") }
        }
    }

    @Test
    fun `should return not found when pinning an etf outside the catalog`() {
        every { etfService.addFavourite("ARKK") } throws EtfNotFoundException()

        mockMvc.put("/etfs/ARKK/favourite").andExpect {
            status { isNotFound() }
            jsonPath("$[0].message") { value("error.etfs.etf-not-found") }
        }
    }

    @Test
    fun `should return no content when an etf is unpinned`() {
        justRun { etfService.removeFavourite("SPY") }

        mockMvc.delete("/etfs/SPY/favourite").andExpect { status { isNoContent() } }
    }

    @Test
    fun `should return bad request when unpinning an invalid ticker`() {
        every { etfService.removeFavourite("SPY$") } throws InvalidTickerException()

        mockMvc.delete("/etfs/SPY$/favourite").andExpect {
            status { isBadRequest() }
            jsonPath("$[0].message") { value("error.etfs.invalid-ticker") }
        }
    }
}

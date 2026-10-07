package com.fisa.indice.etf.controllers

import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.RetrievedEtfCatalog
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
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import java.time.Instant
import kotlin.test.assertEquals

@WebMvcTest(EtfController::class)
class EtfControllerTest(
    @Autowired private val mockMvc: MockMvc,
    @Autowired private val etfService: EtfService,
) {

    @TestConfiguration
    class MockConfig {
        @Bean
        fun etfService(): EtfService = mockk()
    }

    private val fetchedAt = Instant.parse("2026-10-07T08:00:00Z")
    private val etf = Etf("LU1681043599", "CW8", "PA", "Amundi MSCI World UCITS ETF", "EUR", fetchedAt)

    private fun givenServiceReturnsOneEtf(): CapturingSlot<Pageable> {
        val pageable = slot<Pageable>()
        every { etfService.retrieveEtfs(capture(pageable)) } answers {
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
            jsonPath("$.etfs.content[0].isin") { value("LU1681043599") }
            jsonPath("$.etfs.content[0].ticker") { value("CW8") }
            jsonPath("$.etfs.content[0].exchange") { value("PA") }
            jsonPath("$.etfs.content[0].name") { value("Amundi MSCI World UCITS ETF") }
            jsonPath("$.etfs.content[0].currency") { value("EUR") }
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
}

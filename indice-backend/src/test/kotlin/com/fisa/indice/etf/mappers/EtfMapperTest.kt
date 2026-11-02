package com.fisa.indice.etf.mappers

import com.fisa.indice.common.dtos.responses.PageResponseDto
import com.fisa.indice.etf.dtos.twelvedata.TwelveDataEtfDto
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.RetrievedEtfCatalog
import org.junit.jupiter.api.Test
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class EtfMapperTest {

    private val now = Instant.parse("2026-10-07T08:00:00Z")
    private val etf = Etf("SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", now)

    @Test
    fun `should build an etf from a twelve data etf`() {
        // When
        val model = TwelveDataEtfDto("SPY", "SPDR S&P 500 ETF Trust", "USD", "NYSE").toModel(now)

        // Then
        assertEquals(etf.copy(id = model.id), model)
    }

    @Test
    fun `should keep all fields on model to entity round trip`() {
        assertEquals(etf, etf.toEntity().toModel())
    }

    @Test
    fun `should map retrieved catalog to response with page, last synchronization date and stale flag`() {
        // Given
        val page = PageImpl(listOf(etf), PageRequest.of(1, 1), 3)

        // When
        val dto = RetrievedEtfCatalog(page, lastSynchronizedAt = now, stale = true).toDto()

        // Then
        assertEquals(PageResponseDto(listOf(etf.toDto()), page = 1, size = 1, totalElements = 3, totalPages = 3), dto.etfs)
        assertEquals(now, dto.fetchedAt)
        assertTrue(dto.stale)
    }

    @Test
    fun `should carry the favourite flag from entity to response`() {
        // When
        val dto = etf.toEntity().toModel(favourite = true).toDto()

        // Then
        assertTrue(dto.favourite)
    }

    @Test
    fun `should tell whether the etf is leveraged or inverse`() {
        val dto = etf.copy(name = "Direxion Daily S&P 500 Bull 3X Shares").toDto()

        assertTrue(dto.leveragedOrInverse)
    }
}

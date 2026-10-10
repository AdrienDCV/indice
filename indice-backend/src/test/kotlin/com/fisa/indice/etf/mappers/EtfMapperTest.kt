package com.fisa.indice.etf.mappers

import com.fisa.indice.etf.dtos.responses.EodhdSymbolDto
import com.fisa.indice.common.dtos.responses.PageResponseDto
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.RetrievedEtfCatalog
import org.junit.jupiter.api.Test
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import java.time.Instant
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EtfMapperTest {

    private val now = Instant.parse("2026-10-07T08:00:00Z")

    private fun symbol(isin: String?) = EodhdSymbolDto("CW8", "Amundi MSCI World UCITS ETF", "PA", "EUR", isin)

    @Test
    fun `should not build an etf when eodhd isin is null or blank`() {
        assertNull(symbol(null).toModelOrNull(now))
        assertNull(symbol(" ").toModelOrNull(now))
    }

    @Test
    fun `should build an etf when eodhd isin is present`() {
        // When
        val etf = symbol("LU1681043599").toModelOrNull(now)

        // Then
        assertEquals(
            Etf("LU1681043599", "CW8", "PA", "Amundi MSCI World UCITS ETF", "EUR", now, id = etf?.id ?: UUID.randomUUID()),
            etf,
        )
    }

    @Test
    fun `should keep all fields on model to entity round trip`() {
        val etf = Etf("LU1681043599", "CW8", "PA", "Amundi MSCI World UCITS ETF", "EUR", now)

        assertEquals(etf, etf.toEntity().toModel())
    }

    @Test
    fun `should map retrieved catalog to response with page, last synchronization date and stale flag`() {
        // Given
        val etf = Etf("LU1681043599", "CW8", "PA", "Amundi MSCI World UCITS ETF", "EUR", now)
        val page = PageImpl(listOf(etf), PageRequest.of(1, 1), 3)

        // When
        val dto = RetrievedEtfCatalog(page, lastSynchronizedAt = now, stale = true).toDto()

        // Then
        assertEquals(PageResponseDto(listOf(etf.toDto()), page = 1, size = 1, totalElements = 3, totalPages = 3), dto.etfs)
        assertEquals(now, dto.fetchedAt)
        assertTrue(dto.stale)
    }
}

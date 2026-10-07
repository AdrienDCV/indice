package com.fisa.indice.etf.models

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

class EtfTest {

    private val now = Instant.parse("2026-10-07T08:00:00Z")

    private fun etf(isin: String = "LU1681043599", fetchedAt: Instant = now) =
        Etf(isin, "CW8", "PA", "Amundi MSCI World UCITS ETF", "EUR", fetchedAt)

    @Test
    fun `should generate a distinct id for each new etf`() {
        assertNotEquals(etf().id, etf().id)
    }

    @Test
    fun `should reject blank isin`() {
        assertThrows<IllegalArgumentException> { etf(isin = " ") }
    }

    @Test
    fun `should copy source fields but keep its id when refreshed from an etf with the same isin`() {
        // Given
        val original = etf(fetchedAt = now.minusSeconds(60))
        val source = Etf("LU1681043599", "MWRD", "XPAR", "New name", "USD", now)

        // When
        val refreshed = original.refreshedFrom(source)

        // Then
        assertEquals(source.copy(id = original.id), refreshed)
        assertEquals("CW8", original.ticker)
    }

    @Test
    fun `should reject refresh from an etf with another isin`() {
        assertThrows<IllegalArgumentException> { etf().refreshedFrom(etf(isin = "IE00B4L5Y983")) }
    }
}

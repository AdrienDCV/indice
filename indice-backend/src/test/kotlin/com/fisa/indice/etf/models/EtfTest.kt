package com.fisa.indice.etf.models

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

class EtfTest {

    private val now = Instant.parse("2026-10-07T08:00:00Z")

    private fun etf(ticker: String = "SPY", fetchedAt: Instant = now) =
        Etf(ticker, "NYSE", "SPDR S&P 500 ETF Trust", "USD", fetchedAt)

    @Test
    fun `should generate a distinct id for each new etf`() {
        assertNotEquals(etf().id, etf().id)
    }

    @Test
    fun `should reject blank ticker`() {
        assertThrows<IllegalArgumentException> { etf(ticker = " ") }
    }

    @Test
    fun `should copy source fields but keep its id when refreshed from an etf with the same ticker`() {
        // Given
        val original = etf(fetchedAt = now.minusSeconds(60))
        val source = Etf("SPY", "NYSE ARCA", "New name", "USD", now)

        // When
        val refreshed = original.refreshedFrom(source)

        // Then
        assertEquals(source.copy(id = original.id), refreshed)
        assertEquals("SPDR S&P 500 ETF Trust", original.name)
    }

    @Test
    fun `should reject refresh from an etf with another ticker`() {
        assertThrows<IllegalArgumentException> { etf().refreshedFrom(etf(ticker = "QQQ")) }
    }
}

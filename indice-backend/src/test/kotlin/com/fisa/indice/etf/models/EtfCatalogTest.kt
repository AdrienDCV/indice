package com.fisa.indice.etf.models

import org.junit.jupiter.api.Test
import java.time.Duration
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EtfCatalogTest {

    private val now = Instant.parse("2026-10-07T08:00:00Z")
    private val selectedTickers = setOf("SPY", "QQQ", "BND")

    private fun etf(ticker: String, name: String = "ETF $ticker", fetchedAt: Instant = now) =
        Etf(ticker, "NYSE", name, "USD", fetchedAt)

    @Test
    fun `should be stale when never synchronized`() {
        assertTrue(EtfCatalog.isStale(null, now))
    }

    @Test
    fun `should not be stale when synchronized less than 7 days ago`() {
        assertFalse(EtfCatalog.isStale(now.minus(Duration.ofDays(6)), now))
    }

    @Test
    fun `should not be stale when synchronized exactly 7 days ago`() {
        assertFalse(EtfCatalog.isStale(now.minus(Duration.ofDays(7)), now))
    }

    @Test
    fun `should be stale when synchronized more than 7 days ago`() {
        assertTrue(EtfCatalog.isStale(now.minus(Duration.ofDays(7).plusSeconds(1)), now))
    }

    @Test
    fun `should only keep selected etfs when synchronized`() {
        // Given
        val source = listOf(etf("SPY"), etf("ARKK"), etf("QQQ"))

        // When
        val catalog = EtfCatalog(emptyList()).synchronizedWith(source, selectedTickers)

        // Then
        assertEquals(setOf("SPY", "QQQ"), catalog.etfs.map { it.ticker }.toSet())
    }

    @Test
    fun `should keep a single etf when a ticker is listed twice`() {
        // When
        val catalog = EtfCatalog(emptyList()).synchronizedWith(listOf(etf("SPY"), etf("SPY", name = "Duplicate")), selectedTickers)

        // Then
        assertEquals(listOf("SPY"), catalog.etfs.map { it.ticker })
    }

    @Test
    fun `should refresh known etfs keeping their id, add new ones and drop absent ones`() {
        // Given
        val lastWeek = now.minus(Duration.ofDays(8))
        val known = etf("SPY", name = "Old name", fetchedAt = lastWeek)
        val absent = etf("QQQ", fetchedAt = lastWeek)
        val catalog = EtfCatalog(listOf(known, absent))

        // When
        val synchronized = catalog.synchronizedWith(listOf(etf("SPY", name = "New name"), etf("BND")), selectedTickers)

        // Then
        assertEquals(setOf("SPY", "BND"), synchronized.etfs.map { it.ticker }.toSet())
        val refreshed = synchronized.etfs.single { it.ticker == "SPY" }
        assertEquals(known.id, refreshed.id)
        assertEquals("New name", refreshed.name)
        assertTrue(synchronized.etfs.all { it.fetchedAt == now })
    }

    @Test
    fun `should list etfs missing from another catalog`() {
        // Given
        val kept = etf("SPY")
        val removed = etf("QQQ")

        // When
        val missing = EtfCatalog(listOf(kept, removed)).etfsMissingFrom(EtfCatalog(listOf(kept)))

        // Then
        assertEquals(listOf(removed), missing)
    }

    @Test
    fun `should leave original catalog unchanged when synchronized`() {
        // Given
        val original = EtfCatalog(listOf(etf("SPY", name = "Old", fetchedAt = now.minus(Duration.ofDays(8)))))
        val snapshot = original.copy()

        // When
        original.synchronizedWith(listOf(etf("SPY", name = "New")), selectedTickers)

        // Then
        assertEquals(snapshot, original)
    }
}

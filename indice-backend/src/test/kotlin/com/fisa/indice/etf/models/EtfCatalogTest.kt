package com.fisa.indice.etf.models

import org.junit.jupiter.api.Test
import java.time.Duration
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EtfCatalogTest {

    private val now = Instant.parse("2026-10-07T08:00:00Z")
    private val first = "LU1681043599"
    private val second = "LU1681048804"
    private val third = "FR0007052782"
    private val selectedIsins = setOf(first, second, third)

    private fun etf(
        isin: String,
        ticker: String = "T-$isin",
        name: String = "ETF $isin",
        currency: String = "EUR",
        fetchedAt: Instant = now,
    ) = Etf(isin, ticker, "PA", name, currency, fetchedAt)

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
        val source = listOf(etf(first), etf("XS0000000000"), etf(second))

        // When
        val catalog = EtfCatalog(emptyList()).synchronizedWith(source, selectedIsins)

        // Then
        assertEquals(setOf(first, second), catalog.etfs.map { it.isin }.toSet())
    }

    @Test
    fun `should keep the euro listing whatever the source order when an isin is listed twice`() {
        // Given
        val usd = etf(first, ticker = "AAA", currency = "USD")
        val eur = etf(first, ticker = "ZZZ", currency = "EUR")

        // When
        val fromSource = EtfCatalog(emptyList()).synchronizedWith(listOf(usd, eur), selectedIsins)
        val fromReversedSource = EtfCatalog(emptyList()).synchronizedWith(listOf(eur, usd), selectedIsins)

        // Then
        assertEquals(listOf("ZZZ"), fromSource.etfs.map { it.ticker })
        assertEquals(fromSource.etfs.map { it.ticker }, fromReversedSource.etfs.map { it.ticker })
    }

    @Test
    fun `should refresh known etfs keeping their id, add new ones and drop absent ones`() {
        // Given
        val lastWeek = now.minus(Duration.ofDays(8))
        val known = etf(first, name = "Old name", fetchedAt = lastWeek)
        val absent = etf(second, fetchedAt = lastWeek)
        val catalog = EtfCatalog(listOf(known, absent))

        // When
        val synchronized = catalog.synchronizedWith(listOf(etf(first, name = "New name"), etf(third)), selectedIsins)

        // Then
        assertEquals(setOf(first, third), synchronized.etfs.map { it.isin }.toSet())
        val refreshed = synchronized.etfs.single { it.isin == first }
        assertEquals(known.id, refreshed.id)
        assertEquals("New name", refreshed.name)
        assertTrue(synchronized.etfs.all { it.fetchedAt == now })
    }

    @Test
    fun `should list etfs missing from another catalog`() {
        // Given
        val kept = etf(first)
        val removed = etf(second)

        // When
        val missing = EtfCatalog(listOf(kept, removed)).etfsMissingFrom(EtfCatalog(listOf(kept)))

        // Then
        assertEquals(listOf(removed), missing)
    }

    @Test
    fun `should leave original catalog unchanged when synchronized`() {
        // Given
        val original = EtfCatalog(listOf(etf(first, name = "Old", fetchedAt = now.minus(Duration.ofDays(8)))))
        val snapshot = original.copy()

        // When
        original.synchronizedWith(listOf(etf(first, name = "New")), selectedIsins)

        // Then
        assertEquals(snapshot, original)
    }
}

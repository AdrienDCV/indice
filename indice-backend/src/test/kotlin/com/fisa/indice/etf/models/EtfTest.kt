package com.fisa.indice.etf.models

import com.fisa.indice.etf.exceptions.InvalidTickerException
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

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

    @Test
    fun `should normalize ticker to trimmed upper case`() {
        assertEquals("SPY", Etf.normalizeTicker(" spy "))
        assertEquals("BRK.B", Etf.normalizeTicker("brk.b"))
    }

    @Test
    fun `should reject invalid tickers`() {
        listOf("", "SP Y", "SPY$", "ABCDEFGHIJK").forEach {
            assertThrows<InvalidTickerException> { Etf.normalizeTicker(it) }
        }
    }

    private fun named(name: String) = Etf("TEST", "NYSE", name, "USD", now)

    @Test
    fun `should spot leveraged or inverse etfs from their name`() {
        listOf(
            "Direxion Daily Semiconductor Bear 3X Shares",
            "Tradr 2X Long Innovation ETF",
            "Defiance Daily Target 2X Short PLTR ETF",
            "Direxion Daily S&P 500 Bear -1x Shares",
            "ProShares Ultra Communication Services",
            "ProShares UltraShort MidCap400",
            "ProShares UltraPro QQQ",
            "BetaPro Crude Oil Leveraged Daily Bull ETF",
            "AXS 1.25x NVDA Bear Daily ETF",
            "Invesco S&P 500 Inverse ETF",
        ).forEach { assertTrue(named(it).isLeveragedOrInverse(), it) }
    }

    @Test
    fun `should not spot ordinary etfs whose name only looks similar`() {
        listOf(
            "SPDR S&P 500 ETF Trust",
            "Goldman Sachs Ultra Short Bond ETF",
            "ClearShares Ultra-Short Maturity ETF",
            "iShares Short-Term National Muni Bond ETF",
            "xETFs NVDA Daily Income ETF",
            "WisdomTree Efficient Long/Short U.S. SmallCap Equity Fund",
            "Vanguard Russell 2000 ETF",
            "Global X Uranium ETF",
        ).forEach { assertFalse(named(it).isLeveragedOrInverse(), it) }
    }
}

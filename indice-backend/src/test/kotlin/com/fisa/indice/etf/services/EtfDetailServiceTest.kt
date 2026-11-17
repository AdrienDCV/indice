package com.fisa.indice.etf.services

import com.fisa.indice.etf.entities.EtfEntity
import com.fisa.indice.etf.entities.FavouriteEtfEntity
import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.exceptions.InvalidTickerException
import com.fisa.indice.etf.models.ClosingPrice
import com.fisa.indice.etf.models.ClosingPriceHistory
import com.fisa.indice.etf.models.EtfPrices
import com.fisa.indice.etf.repositories.EtfRepository
import com.fisa.indice.etf.repositories.FavouriteEtfRepository
import io.mockk.every
import io.mockk.justRun
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EtfDetailServiceTest {

    private val now = Instant.parse("2026-10-20T08:00:00Z")
    private val etf = EtfEntity(UUID.randomUUID(), "SPY", "NYSE", "SPDR S&P 500 ETF Trust", "USD", now)

    private val etfRepository = mockk<EtfRepository>()
    private val closingPriceService = mockk<ClosingPriceService>()
    private val favouriteEtfRepository = mockk<FavouriteEtfRepository> {
        every { existsById(any()) } returns false
    }
    private val etfDetailService = EtfDetailService(etfRepository, closingPriceService, favouriteEtfRepository)

    private fun price(date: String, close: String) = ClosingPrice(LocalDate.parse(date), BigDecimal(close))

    @Test
    fun `should reject an invalid ticker without querying the database`() {
        assertThrows<InvalidTickerException> { etfDetailService.retrieveEtf("SP Y") }

        verify(exactly = 0) { etfRepository.findByTicker(any()) }
    }

    @Test
    fun `should throw EtfNotFoundException when ticker is not in the catalog`() {
        every { etfRepository.findByTicker("ARKK") } returns null

        assertThrows<EtfNotFoundException> { etfDetailService.retrieveEtf("arkk") }
    }

    @Test
    fun `should compute market data from the etf prices`() {
        // Given
        every { etfRepository.findByTicker("SPY") } returns etf
        val history = ClosingPriceHistory(listOf(price("2025-10-17", "100"), price("2026-10-19", "110")))
        every { closingPriceService.retrievePrices(match { it.ticker == "SPY" }) } returns
            EtfPrices(history, now, stale = false)

        // When
        val detail = etfDetailService.retrieveEtf("spy")

        // Then
        assertEquals(BigDecimal("0.1000"), detail.marketData?.returnOneYear)
        assertEquals(now, detail.closingPricesFetchedAt)
        assertFalse(detail.stale)
    }

    @Test
    fun `should return no market data when no history is available`() {
        // Given
        every { etfRepository.findByTicker("SPY") } returns etf
        every { closingPriceService.retrievePrices(any()) } returns EtfPrices(null, null, stale = true)

        // When
        val detail = etfDetailService.retrieveEtf("SPY")

        // Then
        assertNull(detail.marketData)
        assertNull(detail.closingPricesFetchedAt)
        assertTrue(detail.stale)
        assertEquals("SPY", detail.etf.ticker)
    }

    @Test
    fun `should tell whether the etf is a favourite`() {
        // Given
        every { etfRepository.findByTicker("SPY") } returns etf
        every { favouriteEtfRepository.existsById("SPY") } returns true
        every { closingPriceService.retrievePrices(any()) } returns EtfPrices(null, null, stale = true)

        // When
        val detail = etfDetailService.retrieveEtf("spy")

        // Then
        assertTrue(detail.etf.favourite)
    }

    @Test
    fun `should pin an etf that was not a favourite yet`() {
        // Given
        every { etfRepository.findByTicker("SPY") } returns etf
        every { favouriteEtfRepository.save(FavouriteEtfEntity("SPY")) } returns FavouriteEtfEntity("SPY")
        every { closingPriceService.retrievePrices(any()) } returns EtfPrices(null, null, stale = true)

        // When
        val detail = etfDetailService.addFavourite(" spy ")

        // Then
        assertTrue(detail.etf.favourite)
        verify(exactly = 1) { favouriteEtfRepository.save(FavouriteEtfEntity("SPY")) }
    }

    @Test
    fun `should not pin an etf twice`() {
        // Given
        every { etfRepository.findByTicker("SPY") } returns etf
        every { favouriteEtfRepository.existsById("SPY") } returns true
        every { closingPriceService.retrievePrices(any()) } returns EtfPrices(null, null, stale = true)

        // When
        val detail = etfDetailService.addFavourite("SPY")

        // Then
        assertTrue(detail.etf.favourite)
        verify(exactly = 0) { favouriteEtfRepository.save(any()) }
    }

    @Test
    fun `should throw EtfNotFoundException when pinning an etf outside the catalog`() {
        every { etfRepository.findByTicker("ARKK") } returns null

        assertThrows<EtfNotFoundException> { etfDetailService.addFavourite("ARKK") }
    }

    @Test
    fun `should throw InvalidTickerException when pinning an invalid ticker`() {
        assertThrows<InvalidTickerException> { etfDetailService.addFavourite("SP Y") }
    }

    @Test
    fun `should unpin an etf`() {
        // Given
        justRun { favouriteEtfRepository.deleteById("SPY") }

        // When
        etfDetailService.removeFavourite(" spy ")

        // Then
        verify(exactly = 1) { favouriteEtfRepository.deleteById("SPY") }
    }

    @Test
    fun `should throw InvalidTickerException when unpinning an invalid ticker`() {
        assertThrows<InvalidTickerException> { etfDetailService.removeFavourite("SP Y") }
    }
}

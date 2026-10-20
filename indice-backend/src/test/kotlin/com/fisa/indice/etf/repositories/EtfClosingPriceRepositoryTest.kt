package com.fisa.indice.etf.repositories

import com.fisa.indice.etf.entities.EtfClosingPriceEntity
import com.fisa.indice.etf.entities.EtfEntity
import jakarta.persistence.EntityManager
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import kotlin.test.assertEquals

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class EtfClosingPriceRepositoryTest(
    @Autowired private val etfRepository: EtfRepository,
    @Autowired private val etfClosingPriceRepository: EtfClosingPriceRepository,
    @Autowired private val entityManager: EntityManager,
) {

    private val now = Instant.parse("2026-10-20T08:00:00Z")

    private fun givenEtfWithPrices(ticker: String): EtfEntity {
        val etf = etfRepository.save(EtfEntity(UUID.randomUUID(), ticker, "NYSE", "ETF $ticker", "USD", now))
        etfClosingPriceRepository.saveAll(
            listOf("2026-10-16", "2026-10-19").map {
                EtfClosingPriceEntity(etf.id, LocalDate.parse(it), BigDecimal("100"), now)
            }
        )
        entityManager.flush()
        return etf
    }

    @Test
    fun `should only delete closing prices of the given etf`() {
        // Given
        val deleted = givenEtfWithPrices("TESTA")
        val kept = givenEtfWithPrices("TESTB")

        // When
        etfClosingPriceRepository.deleteAllByEtfId(deleted.id)

        // Then
        assertEquals(0, etfClosingPriceRepository.findAllByEtfIdOrderByTradingDateAsc(deleted.id).size)
        assertEquals(2, etfClosingPriceRepository.findAllByEtfIdOrderByTradingDateAsc(kept.id).size)
    }

    @Test
    fun `should delete closing prices of an etf removed from the catalog`() {
        // Given
        val etf = givenEtfWithPrices("TESTC")

        // When
        etfRepository.deleteAllByIdInBatch(listOf(etf.id))
        entityManager.clear()

        // Then
        assertEquals(0, etfClosingPriceRepository.findAllByEtfIdOrderByTradingDateAsc(etf.id).size)
    }
}

package com.fisa.indice.etf.services

import com.fisa.indice.etf.clients.TwelveDataClient
import com.fisa.indice.etf.exceptions.TwelveDataUnavailableException
import com.fisa.indice.etf.mappers.toEntity
import com.fisa.indice.etf.mappers.toModel
import com.fisa.indice.etf.models.ClosingPrice
import com.fisa.indice.etf.models.ClosingPriceHistory
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.EtfPrices
import com.fisa.indice.etf.repositories.EtfClosingPriceRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset

@Service
class ClosingPriceService(
    private val etfClosingPriceRepository: EtfClosingPriceRepository,
    private val twelveDataClient: TwelveDataClient,
    private val clock: Clock,
) {

    @Transactional
    fun retrievePrices(etf: Etf): EtfPrices {
        val now = Instant.now(clock)
        val fetchedAt = etfClosingPriceRepository.findFirstByEtfIdOrderByFetchedAtDesc(etf.id)?.fetchedAt
        if (!ClosingPriceHistory.isStale(fetchedAt, now)) return retrieveStoredPrices(etf, fetchedAt, stale = false)

        val prices = fetchClosingPrices(etf, now) ?: return retrieveStoredPrices(etf, fetchedAt, stale = true)
        replaceClosingPrices(etf, prices, now)
        return EtfPrices(ClosingPriceHistory.fromUnsorted(prices), now, stale = false)
    }

    private fun retrieveStoredPrices(etf: Etf, fetchedAt: Instant?, stale: Boolean): EtfPrices {
        val prices = etfClosingPriceRepository.findAllByEtfIdOrderByTradingDateAsc(etf.id).map { it.toModel() }
        val history = prices.takeIf { it.isNotEmpty() }?.let { ClosingPriceHistory.fromUnsorted(it) }
        return EtfPrices(history, fetchedAt, stale)
    }

    private fun fetchClosingPrices(etf: Etf, now: Instant): List<ClosingPrice>? {
        val startDate = LocalDate.ofInstant(now, ZoneOffset.UTC).minusYears(HISTORY_YEARS).minusDays(HISTORY_MARGIN_DAYS)
        return try {
            twelveDataClient.fetchDailyClosingPrices(etf.ticker, startDate).map { it.toModel() }
        } catch (_: TwelveDataUnavailableException) {
            logger.warn("Récupération des cours de {} impossible : Twelve Data indisponible", etf.ticker)
            null
        }
    }

    private fun replaceClosingPrices(etf: Etf, prices: List<ClosingPrice>, fetchedAt: Instant) {
        etfClosingPriceRepository.deleteAllByEtfId(etf.id)
        etfClosingPriceRepository.saveAll(prices.map { it.toEntity(etf.id, fetchedAt) })
    }

    companion object {
        private const val HISTORY_YEARS = 5L
        private const val HISTORY_MARGIN_DAYS = 7L
        private val logger = LoggerFactory.getLogger(ClosingPriceService::class.java)
    }
}

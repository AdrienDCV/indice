package com.fisa.indice.etf.services

import com.fisa.indice.etf.clients.TwelveDataClient
import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.exceptions.TwelveDataUnavailableException
import com.fisa.indice.etf.mappers.toEntity
import com.fisa.indice.etf.mappers.toModel
import com.fisa.indice.etf.models.ClosingPrice
import com.fisa.indice.etf.models.ClosingPriceHistory
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.EtfDetail
import com.fisa.indice.etf.repositories.EtfClosingPriceRepository
import com.fisa.indice.etf.repositories.EtfRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset

@Service
class EtfDetailService(
    private val etfRepository: EtfRepository,
    private val etfClosingPriceRepository: EtfClosingPriceRepository,
    private val twelveDataClient: TwelveDataClient,
    private val clock: Clock,
) {

    @Transactional
    fun retrieveEtf(ticker: String): EtfDetail {
        val etf = findEtf(Etf.normalizeTicker(ticker))
        val now = Instant.now(clock)
        val fetchedAt = etfClosingPriceRepository.findFirstByEtfIdOrderByFetchedAtDesc(etf.id)?.fetchedAt
        if (!ClosingPriceHistory.isStale(fetchedAt, now)) return retrieveDetail(etf, fetchedAt, stale = false)

        val prices = fetchClosingPrices(etf, now) ?: return retrieveDetail(etf, fetchedAt, stale = true)
        replaceClosingPrices(etf, prices, now)
        return EtfDetail(etf, ClosingPriceHistory.fromUnsorted(prices).marketData(), now, stale = false)
    }

    private fun findEtf(ticker: String): Etf =
        etfRepository.findByTicker(ticker)?.toModel() ?: throw EtfNotFoundException()

    private fun retrieveDetail(etf: Etf, fetchedAt: Instant?, stale: Boolean): EtfDetail {
        val prices = etfClosingPriceRepository.findAllByEtfIdOrderByTradingDateAsc(etf.id).map { it.toModel() }
        val marketData = prices.takeIf { it.isNotEmpty() }?.let { ClosingPriceHistory.fromUnsorted(it).marketData() }
        return EtfDetail(etf, marketData, fetchedAt, stale)
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
        private val logger = LoggerFactory.getLogger(EtfDetailService::class.java)
    }
}

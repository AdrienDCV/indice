package com.fisa.indice.etf.services

import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.exceptions.SameEtfComparisonException
import com.fisa.indice.etf.mappers.toModel
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.EtfComparison
import com.fisa.indice.etf.repositories.EtfRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class EtfComparisonService(
    private val etfRepository: EtfRepository,
    private val closingPriceService: ClosingPriceService,
) {

    @Transactional
    fun compare(tickerA: String, tickerB: String): EtfComparison {
        val normalizedTickerA = Etf.normalizeTicker(tickerA)
        val normalizedTickerB = Etf.normalizeTicker(tickerB)
        if (normalizedTickerA == normalizedTickerB) throw SameEtfComparisonException()

        val etfA = findEtf(normalizedTickerA)
        val etfB = findEtf(normalizedTickerB)
        return EtfComparison.between(
            etfA, closingPriceService.retrievePrices(etfA),
            etfB, closingPriceService.retrievePrices(etfB),
        )
    }

    private fun findEtf(ticker: String): Etf =
        etfRepository.findByTicker(ticker)?.toModel() ?: throw EtfNotFoundException()
}

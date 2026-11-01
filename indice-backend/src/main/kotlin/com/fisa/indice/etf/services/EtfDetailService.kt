package com.fisa.indice.etf.services

import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.mappers.toModel
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.EtfDetail
import com.fisa.indice.etf.repositories.EtfRepository
import com.fisa.indice.etf.repositories.FavouriteEtfRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class EtfDetailService(
    private val etfRepository: EtfRepository,
    private val closingPriceService: ClosingPriceService,
    private val favouriteEtfRepository: FavouriteEtfRepository,
) {

    @Transactional
    fun retrieveEtf(ticker: String): EtfDetail {
        val etf = findEtf(Etf.normalizeTicker(ticker))
        val prices = closingPriceService.retrievePrices(etf)
        return EtfDetail(etf, prices.history?.marketData(), prices.fetchedAt, prices.stale)
    }

    private fun findEtf(ticker: String): Etf =
        etfRepository.findByTicker(ticker)?.toModel(favourite = favouriteEtfRepository.existsById(ticker))
            ?: throw EtfNotFoundException()
}

package com.fisa.indice.etf.services

import com.fisa.indice.etf.entities.EtfEntity
import com.fisa.indice.etf.entities.FavouriteEtfEntity
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
        val normalizedTicker = Etf.normalizeTicker(ticker)
        val favourite = favouriteEtfRepository.existsById(normalizedTicker)
        val etf = findEtf(normalizedTicker).toModel(favourite = favourite)
        return detailOf(etf)
    }

    @Transactional
    fun addFavourite(ticker: String): EtfDetail {
        val normalizedTicker = Etf.normalizeTicker(ticker)
        val etf = findEtf(normalizedTicker)
        favouriteEtfRepository.save(FavouriteEtfEntity(normalizedTicker))
        return detailOf(etf.toModel(favourite = true))
    }

    @Transactional
    fun removeFavourite(ticker: String) {
        favouriteEtfRepository.deleteById(Etf.normalizeTicker(ticker))
    }

    private fun findEtf(ticker: String): EtfEntity =
        etfRepository.findByTicker(ticker) ?: throw EtfNotFoundException()

    private fun detailOf(etf: Etf): EtfDetail {
        val prices = closingPriceService.retrievePrices(etf)
        return EtfDetail(etf, prices.history?.marketData(), prices.fetchedAt, prices.stale)
    }
}

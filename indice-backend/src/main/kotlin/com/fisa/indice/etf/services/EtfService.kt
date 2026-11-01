package com.fisa.indice.etf.services

import com.fisa.indice.etf.clients.TwelveDataClient
import com.fisa.indice.etf.config.EtfCatalogProperties
import com.fisa.indice.etf.entities.FavouriteEtfEntity
import com.fisa.indice.etf.exceptions.EtfNotFoundException
import com.fisa.indice.etf.exceptions.TwelveDataUnavailableException
import com.fisa.indice.etf.mappers.toEntity
import com.fisa.indice.etf.mappers.toModel
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.EtfCatalog
import com.fisa.indice.etf.models.RetrievedEtfCatalog
import com.fisa.indice.etf.repositories.EtfRepository
import com.fisa.indice.etf.repositories.FavouriteEtfRepository
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant

@Service
class EtfService(
    private val etfRepository: EtfRepository,
    private val twelveDataClient: TwelveDataClient,
    private val clock: Clock,
    private val etfCatalogProperties: EtfCatalogProperties,
    private val favouriteEtfRepository: FavouriteEtfRepository,
) {

    @Transactional
    fun retrieveEtfs(pageable: Pageable, search: String?, favouritesOnly: Boolean): RetrievedEtfCatalog {
        val now = Instant.now(clock)
        val lastSynchronizedAt = etfRepository.findFirstByOrderByFetchedAtDesc()?.fetchedAt
        val normalizedSearch = search?.trim()?.lowercase().orEmpty()
        if (!EtfCatalog.isStale(lastSynchronizedAt, now)) {
            return RetrievedEtfCatalog(retrievePage(pageable, normalizedSearch, favouritesOnly), lastSynchronizedAt, stale = false)
        }

        val source = fetchSource(now)
            ?: return RetrievedEtfCatalog(retrievePage(pageable, normalizedSearch, favouritesOnly), lastSynchronizedAt, stale = true)
        synchronize(source)
        return RetrievedEtfCatalog(retrievePage(pageable, normalizedSearch, favouritesOnly), now, stale = false)
    }

    @Transactional
    fun addFavourite(ticker: String): Boolean {
        val normalizedTicker = Etf.normalizeTicker(ticker)
        if (etfRepository.findByTicker(normalizedTicker) == null) throw EtfNotFoundException()
        if (favouriteEtfRepository.existsById(normalizedTicker)) return false
        favouriteEtfRepository.save(FavouriteEtfEntity(normalizedTicker))
        return true
    }

    @Transactional
    fun removeFavourite(ticker: String) {
        favouriteEtfRepository.deleteById(Etf.normalizeTicker(ticker))
    }

    private fun retrievePage(pageable: Pageable, search: String, favouritesOnly: Boolean): Page<Etf> {
        val page = etfRepository.findInCatalog(search, favouritesOnly, pageable)
        val favouriteTickers = favouriteEtfRepository.findAllById(page.content.map { it.ticker }).mapTo(HashSet()) { it.ticker }
        return page.map { it.toModel(favourite = it.ticker in favouriteTickers) }
    }

    private fun fetchSource(fetchedAt: Instant): List<Etf>? {
        val etfs = try {
            twelveDataClient.fetchEtfs(etfCatalogProperties.country)
        } catch (_: TwelveDataUnavailableException) {
            logger.warn("Rafraîchissement du catalogue d'ETF impossible : Twelve Data indisponible")
            return null
        }
        val source = etfs.map { it.toModel(fetchedAt) }
        if (source.isEmpty()) {
            logger.warn("Rafraîchissement du catalogue d'ETF ignoré : aucun ETF dans la réponse de Twelve Data")
            return null
        }
        return source
    }

    private fun synchronize(source: List<Etf>) {
        val catalog = EtfCatalog(etfRepository.findAll().map { it.toModel() })
        val synchronized = catalog.synchronizedWith(source)
        val removedIds = catalog.etfsMissingFrom(synchronized).map { it.id }
        if (removedIds.isNotEmpty()) etfRepository.deleteAllByIdInBatch(removedIds)
        etfRepository.saveAll(synchronized.etfs.map { it.toEntity() })
    }

    companion object {
        private val logger = LoggerFactory.getLogger(EtfService::class.java)
    }
}

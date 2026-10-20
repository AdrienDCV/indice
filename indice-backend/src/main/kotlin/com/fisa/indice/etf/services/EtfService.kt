package com.fisa.indice.etf.services

import com.fisa.indice.etf.clients.TwelveDataClient
import com.fisa.indice.etf.config.EtfCatalogProperties
import com.fisa.indice.etf.exceptions.TwelveDataUnavailableException
import com.fisa.indice.etf.mappers.toEntity
import com.fisa.indice.etf.mappers.toModel
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.EtfCatalog
import com.fisa.indice.etf.models.RetrievedEtfCatalog
import com.fisa.indice.etf.repositories.EtfRepository
import org.slf4j.LoggerFactory
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
) {

    @Transactional
    fun retrieveEtfs(pageable: Pageable): RetrievedEtfCatalog {
        val now = Instant.now(clock)
        val lastSynchronizedAt = etfRepository.findFirstByOrderByFetchedAtDesc()?.fetchedAt
        if (!EtfCatalog.isStale(lastSynchronizedAt, now)) return retrievePage(pageable, lastSynchronizedAt, stale = false)

        val source = fetchSource(now) ?: return retrievePage(pageable, lastSynchronizedAt, stale = true)
        synchronize(source)
        return retrievePage(pageable, now, stale = false)
    }

    private fun retrievePage(pageable: Pageable, lastSynchronizedAt: Instant?, stale: Boolean) = RetrievedEtfCatalog(
        etfs = etfRepository.findAll(pageable).map { it.toModel() },
        lastSynchronizedAt = lastSynchronizedAt,
        stale = stale,
    )

    private fun fetchSource(fetchedAt: Instant): List<Etf>? {
        val etfs = try {
            twelveDataClient.fetchEtfs(etfCatalogProperties.country)
        } catch (_: TwelveDataUnavailableException) {
            logger.warn("Rafraîchissement du catalogue d'ETF impossible : Twelve Data indisponible")
            return null
        }
        val source = etfs
            .filter { it.symbol in etfCatalogProperties.selectedTickers }
            .map { it.toModel(fetchedAt) }
        if (source.isEmpty()) {
            logger.warn("Rafraîchissement du catalogue d'ETF ignoré : aucun ETF sélectionné dans la réponse de Twelve Data")
            return null
        }
        return source
    }

    private fun synchronize(source: List<Etf>) {
        val catalog = EtfCatalog(etfRepository.findAll().map { it.toModel() })
        val synchronized = catalog.synchronizedWith(source, etfCatalogProperties.selectedTickers)
        val removedIds = catalog.etfsMissingFrom(synchronized).map { it.id }
        if (removedIds.isNotEmpty()) etfRepository.deleteAllByIdInBatch(removedIds)
        etfRepository.saveAll(synchronized.etfs.map { it.toEntity() })
    }

    companion object {
        private val logger = LoggerFactory.getLogger(EtfService::class.java)
    }
}

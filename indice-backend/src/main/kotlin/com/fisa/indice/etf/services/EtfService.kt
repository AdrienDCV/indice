package com.fisa.indice.etf.services

import com.fisa.indice.etf.clients.EodhdClient
import com.fisa.indice.etf.config.EtfCatalogProperties
import com.fisa.indice.etf.exceptions.EodhdDataUnavailableException
import com.fisa.indice.etf.mappers.toEntity
import com.fisa.indice.etf.mappers.toModel
import com.fisa.indice.etf.mappers.toModelOrNull
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
    private val eodhdClient: EodhdClient,
    private val clock: Clock,
    etfCatalogProperties: EtfCatalogProperties,
) {
    private val selectedIsins: Set<String> = etfCatalogProperties.selectedIsins

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
        val symbols = try {
            eodhdClient.fetchEtfs(EXCHANGE)
        } catch (_: EodhdDataUnavailableException) {
            logger.warn("Rafraîchissement du catalogue d'ETF impossible : données EODHD indisponibles")
            return null
        }
        val source = symbols.asSequence()
            .filter { it.isin in selectedIsins }
            .mapNotNull { it.toModelOrNull(fetchedAt) }
            .toList()
        if (source.isEmpty()) {
            logger.warn("Rafraîchissement du catalogue d'ETF ignoré : aucun ETF sélectionné dans la réponse EODHD")
            return null
        }
        return source
    }

    private fun synchronize(source: List<Etf>) {
        val catalog = EtfCatalog(etfRepository.findAll().map { it.toModel() })
        val synchronized = catalog.synchronizedWith(source, selectedIsins)
        val removedIds = catalog.etfsMissingFrom(synchronized).map { it.id }
        if (removedIds.isNotEmpty()) etfRepository.deleteAllByIdInBatch(removedIds)
        etfRepository.saveAll(synchronized.etfs.map { it.toEntity() })
    }

    companion object {
        const val EXCHANGE = "PA"
        private val logger = LoggerFactory.getLogger(EtfService::class.java)
    }
}

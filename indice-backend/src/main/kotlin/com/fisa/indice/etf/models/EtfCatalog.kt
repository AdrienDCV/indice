package com.fisa.indice.etf.models

import java.time.Duration
import java.time.Instant

data class EtfCatalog(val etfs: List<Etf>) {

    fun synchronizedWith(source: List<Etf>, selectedIsins: Set<String>): EtfCatalog {
        val currentByIsin = etfs.associateBy { it.isin }
        return EtfCatalog(
            source
                .filter { it.isin in selectedIsins }
                .sortedWith(PREFERRED_LISTING_FIRST)
                .distinctBy { it.isin }
                .map { candidate -> currentByIsin[candidate.isin]?.refreshedFrom(candidate) ?: candidate }
        )
    }

    fun etfsMissingFrom(other: EtfCatalog): List<Etf> {
        val remainingIds = other.etfs.mapTo(HashSet()) { it.id }
        return etfs.filterNot { it.id in remainingIds }
    }

    companion object {
        val TTL: Duration = Duration.ofDays(7)

        private const val PREFERRED_CURRENCY = "EUR"
        private val PREFERRED_LISTING_FIRST = compareBy<Etf>({ it.currency != PREFERRED_CURRENCY }, { it.ticker })

        fun isStale(lastSynchronizedAt: Instant?, now: Instant): Boolean =
            lastSynchronizedAt == null || lastSynchronizedAt.plus(TTL).isBefore(now)
    }
}

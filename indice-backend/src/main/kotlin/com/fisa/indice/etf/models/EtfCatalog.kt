package com.fisa.indice.etf.models

import java.time.Duration
import java.time.Instant

data class EtfCatalog(val etfs: List<Etf>) {

    fun synchronizedWith(source: List<Etf>): EtfCatalog {
        val currentByTicker = etfs.associateBy { it.ticker }
        return EtfCatalog(
            source
                .distinctBy { it.ticker }
                .map { candidate -> currentByTicker[candidate.ticker]?.refreshedFrom(candidate) ?: candidate }
        )
    }

    fun etfsMissingFrom(other: EtfCatalog): List<Etf> {
        val remainingIds = other.etfs.mapTo(HashSet()) { it.id }
        return etfs.filterNot { it.id in remainingIds }
    }

    companion object {
        val TTL: Duration = Duration.ofDays(7)

        fun isStale(lastSynchronizedAt: Instant?, now: Instant): Boolean =
            lastSynchronizedAt == null || lastSynchronizedAt.plus(TTL).isBefore(now)
    }
}

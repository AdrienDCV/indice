package com.fisa.indice.etf.models

import java.time.Instant
import java.util.UUID

data class Etf(
    val isin: String,
    val ticker: String,
    val exchange: String,
    val name: String,
    val currency: String,
    val fetchedAt: Instant,
    val id: UUID = UUID.randomUUID(),
) {
    init {
        require(isin.isNotBlank()) { "An ETF must have an ISIN" }
    }

    fun refreshedFrom(source: Etf): Etf {
        require(source.isin == isin) { "Cannot refresh ETF $isin from ETF ${source.isin}" }
        return source.copy(id = id)
    }
}

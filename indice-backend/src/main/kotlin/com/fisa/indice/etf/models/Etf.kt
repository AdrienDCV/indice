package com.fisa.indice.etf.models

import java.time.Instant
import java.util.UUID

data class Etf(
    val ticker: String,
    val exchange: String,
    val name: String,
    val currency: String,
    val fetchedAt: Instant,
    val id: UUID = UUID.randomUUID(),
) {
    init {
        require(ticker.isNotBlank()) { "An ETF must have a ticker" }
    }

    fun refreshedFrom(source: Etf): Etf {
        require(source.ticker == ticker) { "Cannot refresh ETF $ticker from ETF ${source.ticker}" }
        return source.copy(id = id)
    }
}

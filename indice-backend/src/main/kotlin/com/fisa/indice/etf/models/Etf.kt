package com.fisa.indice.etf.models

import com.fisa.indice.etf.exceptions.InvalidTickerException
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

    companion object {
        private val TICKER_FORMAT = Regex("^[A-Z0-9.-]{1,10}$")

        fun normalizeTicker(raw: String): String {
            val ticker = raw.trim().uppercase()
            if (!TICKER_FORMAT.matches(ticker)) throw InvalidTickerException()
            return ticker
        }
    }
}

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
    val favourite: Boolean = false,
    val id: UUID = UUID.randomUUID(),
) {
    init {
        require(ticker.isNotBlank()) { "An ETF must have a ticker" }
    }

    /**
     * Vrai si le nom de l'ETF indique un effet de levier ou une stratégie inverse : un multiplicateur
     * (« 2x », « -1x »), les mots « Inverse » ou « Leveraged », ou les gammes ProShares « Ultra », « UltraPro »
     * et « UltraShort ». Twelve Data ne fournit pas cette information : c'est une indication, qui peut manquer
     * un ETF dont le nom ne le dit pas (voir l'ADR 0003).
     */
    fun isLeveragedOrInverse(): Boolean = LEVERAGED_OR_INVERSE_NAME.containsMatchIn(name)

    fun refreshedFrom(source: Etf): Etf {
        require(source.ticker == ticker) { "Cannot refresh ETF $ticker from ETF ${source.ticker}" }
        return source.copy(id = id)
    }

    companion object {
        private val TICKER_FORMAT = Regex("^[A-Z0-9.-]{1,10}$")
        private val LEVERAGED_OR_INVERSE_NAME = Regex(
            """(?<![0-9.])-?[1-9](\.[0-9]+)?x(?![a-z])|\binverse\b|\bleveraged?\b|^proshares ultra(pro|short)?\b""",
            RegexOption.IGNORE_CASE,
        )

        fun normalizeTicker(raw: String): String {
            val ticker = raw.trim().uppercase()
            if (!TICKER_FORMAT.matches(ticker)) throw InvalidTickerException()
            return ticker
        }
    }
}

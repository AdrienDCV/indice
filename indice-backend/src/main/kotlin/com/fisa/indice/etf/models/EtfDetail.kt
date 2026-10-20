package com.fisa.indice.etf.models

import java.time.Instant

data class EtfDetail(
    val etf: Etf,
    val marketData: MarketData?,
    val closingPricesFetchedAt: Instant?,
    val stale: Boolean,
)

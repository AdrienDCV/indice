package com.fisa.indice.etf.models

import java.time.Instant

data class EtfPrices(
    val history: ClosingPriceHistory?,
    val fetchedAt: Instant?,
    val stale: Boolean,
)

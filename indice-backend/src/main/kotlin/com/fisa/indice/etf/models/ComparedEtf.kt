package com.fisa.indice.etf.models

import java.time.Instant

data class ComparedEtf(
    val etf: Etf,
    val performance: Performance,
    val rebasedPrices: List<RebasedPrice>,
    val fetchedAt: Instant?,
    val stale: Boolean,
)

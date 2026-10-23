package com.fisa.indice.etf.models

import java.time.Instant

data class ComparedEtf(
    val etf: Etf,
    val performance: Performance,
    val pricePoints: List<PricePoint>,
    val fetchedAt: Instant?,
    val stale: Boolean,
)

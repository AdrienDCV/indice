package com.fisa.indice.etf.dtos.responses

import java.time.Instant

data class ComparedEtfResponseDto(
    val ticker: String,
    val exchange: String,
    val name: String,
    val currency: String,
    val fetchedAt: Instant?,
    val stale: Boolean,
    val performance: PerformanceResponseDto,
    val rebasedPrices: List<RebasedPriceResponseDto>,
)

package com.fisa.indice.etf.dtos.responses

import java.time.Instant

data class EtfDetailResponseDto(
    val ticker: String,
    val exchange: String,
    val name: String,
    val currency: String,
    val marketData: MarketDataResponseDto?,
    val fetchedAt: Instant?,
    val stale: Boolean,
)

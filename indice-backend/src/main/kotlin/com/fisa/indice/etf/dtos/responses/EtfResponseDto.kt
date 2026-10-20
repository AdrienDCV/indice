package com.fisa.indice.etf.dtos.responses

data class EtfResponseDto(
    val ticker: String,
    val exchange: String,
    val name: String,
    val currency: String,
)

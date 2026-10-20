package com.fisa.indice.etf.dtos.twelvedata

data class TwelveDataTimeSeriesDto(
    val values: List<TwelveDataPriceDto>?,
    val status: String?,
)

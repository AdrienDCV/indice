package com.fisa.indice.etf.dtos.responses

import java.math.BigDecimal

data class PriceRangeResponseDto(
    val low: BigDecimal,
    val high: BigDecimal,
    val position: BigDecimal,
)

package com.fisa.indice.etf.dtos.responses

import java.math.BigDecimal
import java.time.LocalDate

data class PricePointResponseDto(
    val date: LocalDate,
    val close: BigDecimal,
    val changeSinceStart: BigDecimal,
)

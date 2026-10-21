package com.fisa.indice.etf.dtos.responses

import java.math.BigDecimal
import java.time.LocalDate

data class RebasedPriceResponseDto(
    val date: LocalDate,
    val value: BigDecimal,
)

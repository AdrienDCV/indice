package com.fisa.indice.etf.dtos.responses

import java.math.BigDecimal
import java.time.LocalDate

data class MaxDrawdownResponseDto(
    val value: BigDecimal,
    val peakDate: LocalDate,
    val troughDate: LocalDate,
)

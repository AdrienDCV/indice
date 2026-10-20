package com.fisa.indice.etf.dtos.responses

import java.math.BigDecimal

data class ReturnsResponseDto(
    val oneYear: BigDecimal?,
    val threeYears: BigDecimal?,
    val fiveYears: BigDecimal?,
    val fiveYearsAnnualized: BigDecimal?,
)

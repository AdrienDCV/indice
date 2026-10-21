package com.fisa.indice.etf.dtos.responses

import java.math.BigDecimal

data class PerformanceResponseDto(
    val totalReturn: BigDecimal,
    val annualizedReturn: BigDecimal?,
    val volatility: BigDecimal?,
    val returnToRiskRatio: BigDecimal?,
    val maxDrawdown: MaxDrawdownResponseDto,
)

package com.fisa.indice.etf.models

import java.math.BigDecimal

data class Performance(
    val totalReturn: BigDecimal,
    val annualizedReturn: BigDecimal?,
    val volatility: BigDecimal?,
    val returnToRiskRatio: BigDecimal?,
    val maxDrawdown: Drawdown,
)

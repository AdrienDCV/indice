package com.fisa.indice.etf.models

import java.math.BigDecimal
import java.time.LocalDate

data class PricePoint(
    val date: LocalDate,
    val close: BigDecimal,
    val changeSinceStart: BigDecimal
)

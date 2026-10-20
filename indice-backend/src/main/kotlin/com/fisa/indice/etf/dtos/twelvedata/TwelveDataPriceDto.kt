package com.fisa.indice.etf.dtos.twelvedata

import java.math.BigDecimal
import java.time.LocalDate

data class TwelveDataPriceDto(
    val datetime: LocalDate,
    val close: BigDecimal,
)

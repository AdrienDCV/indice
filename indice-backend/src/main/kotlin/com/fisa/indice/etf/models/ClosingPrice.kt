package com.fisa.indice.etf.models

import java.math.BigDecimal
import java.time.LocalDate

data class ClosingPrice(val date: LocalDate, val adjustedClose: BigDecimal) {
    init {
        require(adjustedClose.signum() > 0) { "A closing price must be positive" }
    }
}

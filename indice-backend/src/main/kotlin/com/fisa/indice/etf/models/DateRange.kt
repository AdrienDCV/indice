package com.fisa.indice.etf.models

import java.time.LocalDate

data class DateRange(val startDate: LocalDate, val endDate: LocalDate) {
    init {
        require(startDate <= endDate) { "A date range cannot end before it starts" }
    }
}

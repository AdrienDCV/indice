package com.fisa.indice.etf.dtos.responses

import java.time.LocalDate

data class DateRangeResponseDto(
    val startDate: LocalDate,
    val endDate: LocalDate,
)

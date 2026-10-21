package com.fisa.indice.etf.dtos.responses

import java.math.BigDecimal

data class EtfComparisonResponseDto(
    val commonPeriod: DateRangeResponseDto,
    val correlation: BigDecimal?,
    val etfA: ComparedEtfResponseDto,
    val etfB: ComparedEtfResponseDto,
)

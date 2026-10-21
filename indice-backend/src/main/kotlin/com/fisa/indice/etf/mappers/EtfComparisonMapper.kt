package com.fisa.indice.etf.mappers

import com.fisa.indice.etf.dtos.responses.ComparedEtfResponseDto
import com.fisa.indice.etf.dtos.responses.DateRangeResponseDto
import com.fisa.indice.etf.dtos.responses.EtfComparisonResponseDto
import com.fisa.indice.etf.dtos.responses.PerformanceResponseDto
import com.fisa.indice.etf.dtos.responses.RebasedPriceResponseDto
import com.fisa.indice.etf.models.ComparedEtf
import com.fisa.indice.etf.models.DateRange
import com.fisa.indice.etf.models.EtfComparison
import com.fisa.indice.etf.models.Performance
import com.fisa.indice.etf.models.RebasedPrice

fun EtfComparison.toDto(): EtfComparisonResponseDto = EtfComparisonResponseDto(
    commonPeriod = commonPeriod.toDto(),
    correlation = correlation,
    etfA = etfA.toDto(),
    etfB = etfB.toDto(),
)

fun ComparedEtf.toDto(): ComparedEtfResponseDto = ComparedEtfResponseDto(
    ticker = etf.ticker,
    exchange = etf.exchange,
    name = etf.name,
    currency = etf.currency,
    fetchedAt = fetchedAt,
    stale = stale,
    performance = performance.toDto(),
    rebasedPrices = rebasedPrices.map { it.toDto() },
)

fun Performance.toDto(): PerformanceResponseDto = PerformanceResponseDto(
    totalReturn = totalReturn,
    annualizedReturn = annualizedReturn,
    volatility = volatility,
    returnToRiskRatio = returnToRiskRatio,
    maxDrawdown = maxDrawdown.toDto(),
)

fun RebasedPrice.toDto(): RebasedPriceResponseDto = RebasedPriceResponseDto(
    date = date,
    value = value,
)

fun DateRange.toDto(): DateRangeResponseDto = DateRangeResponseDto(
    startDate = startDate,
    endDate = endDate,
)

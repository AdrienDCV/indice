package com.fisa.indice.etf.mappers

import com.fisa.indice.etf.dtos.responses.ComparedEtfResponseDto
import com.fisa.indice.etf.dtos.responses.DateRangeResponseDto
import com.fisa.indice.etf.dtos.responses.EtfComparisonResponseDto
import com.fisa.indice.etf.dtos.responses.PerformanceResponseDto
import com.fisa.indice.etf.models.ComparedEtf
import com.fisa.indice.etf.models.DateRange
import com.fisa.indice.etf.models.EtfComparison
import com.fisa.indice.etf.models.Performance

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
    pricePoints = pricePoints.map { it.toDto() },
)

fun Performance.toDto(): PerformanceResponseDto = PerformanceResponseDto(
    totalReturn = totalReturn,
    annualizedReturn = annualizedReturn,
    volatility = volatility,
    returnToRiskRatio = returnToRiskRatio,
    maxDrawdown = maxDrawdown.toDto(),
)

fun DateRange.toDto(): DateRangeResponseDto = DateRangeResponseDto(
    startDate = startDate,
    endDate = endDate,
)

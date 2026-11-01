package com.fisa.indice.etf.mappers

import com.fisa.indice.etf.dtos.responses.EtfDetailResponseDto
import com.fisa.indice.etf.dtos.responses.MarketDataResponseDto
import com.fisa.indice.etf.dtos.responses.MaxDrawdownResponseDto
import com.fisa.indice.etf.dtos.responses.PricePointResponseDto
import com.fisa.indice.etf.dtos.responses.PriceRangeResponseDto
import com.fisa.indice.etf.dtos.responses.ReturnsResponseDto
import com.fisa.indice.etf.models.Drawdown
import com.fisa.indice.etf.models.EtfDetail
import com.fisa.indice.etf.models.MarketData
import com.fisa.indice.etf.models.PricePoint
import com.fisa.indice.etf.models.PriceRange

fun EtfDetail.toDto(): EtfDetailResponseDto = EtfDetailResponseDto(
    ticker = etf.ticker,
    exchange = etf.exchange,
    name = etf.name,
    currency = etf.currency,
    marketData = marketData?.toDto(),
    fetchedAt = closingPricesFetchedAt,
    stale = stale,
    favourite = etf.favourite,
)

fun MarketData.toDto(): MarketDataResponseDto = MarketDataResponseDto(
    lastClose = lastClose.adjustedClose,
    lastCloseDate = lastClose.date,
    historyStartDate = historyStartDate,
    returns = ReturnsResponseDto(
        oneYear = returnOneYear,
        threeYears = returnThreeYears,
        fiveYears = returnFiveYears,
        fiveYearsAnnualized = annualizedReturnFiveYears,
    ),
    volatilityOneYear = volatilityOneYear,
    maxDrawdown = maxDrawdownFiveYears?.toDto(),
    fiftyTwoWeekRange = fiftyTwoWeekRange?.toDto(),
    pricePoints = pricePoints.map { it.toDto() },
)

fun Drawdown.toDto(): MaxDrawdownResponseDto = MaxDrawdownResponseDto(
    value = value,
    peakDate = peakDate,
    troughDate = troughDate,
)

fun PriceRange.toDto(): PriceRangeResponseDto = PriceRangeResponseDto(
    low = low,
    high = high,
    position = position,
)

fun PricePoint.toDto(): PricePointResponseDto = PricePointResponseDto(
    date = date,
    close = close,
    changeSinceStart = changeSinceStart,
)

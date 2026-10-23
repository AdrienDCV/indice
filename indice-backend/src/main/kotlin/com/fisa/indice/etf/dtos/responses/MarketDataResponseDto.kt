package com.fisa.indice.etf.dtos.responses

import java.math.BigDecimal
import java.time.LocalDate

data class MarketDataResponseDto(
    val lastClose: BigDecimal,
    val lastCloseDate: LocalDate,
    val historyStartDate: LocalDate,
    val returns: ReturnsResponseDto,
    val volatilityOneYear: BigDecimal?,
    val maxDrawdown: MaxDrawdownResponseDto?,
    val fiftyTwoWeekRange: PriceRangeResponseDto?,
    val pricePoints: List<PricePointResponseDto>,
)

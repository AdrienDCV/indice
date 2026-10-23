package com.fisa.indice.etf.models

import java.math.BigDecimal
import java.time.LocalDate

data class MarketData(
    val lastClose: ClosingPrice,
    val historyStartDate: LocalDate,
    val returnOneYear: BigDecimal?,
    val returnThreeYears: BigDecimal?,
    val returnFiveYears: BigDecimal?,
    val annualizedReturnFiveYears: BigDecimal?,
    val volatilityOneYear: BigDecimal?,
    val maxDrawdownFiveYears: Drawdown?,
    val fiftyTwoWeekRange: PriceRange?,
    val pricePoints: List<PricePoint>,
)

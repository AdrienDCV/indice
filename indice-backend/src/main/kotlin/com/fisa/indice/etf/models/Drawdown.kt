package com.fisa.indice.etf.models

import java.math.BigDecimal
import java.time.LocalDate

data class Drawdown(val value: BigDecimal, val peakDate: LocalDate, val troughDate: LocalDate)

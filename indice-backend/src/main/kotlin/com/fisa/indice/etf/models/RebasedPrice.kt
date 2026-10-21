package com.fisa.indice.etf.models

import java.math.BigDecimal
import java.time.LocalDate

data class RebasedPrice(val date: LocalDate, val value: BigDecimal)

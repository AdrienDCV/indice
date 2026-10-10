package com.fisa.indice.etf.dtos.responses

import com.fasterxml.jackson.annotation.JsonProperty

data class EodhdSymbolDto(
    @JsonProperty("Code") val code: String,
    @JsonProperty("Name") val name: String,
    @JsonProperty("Exchange") val exchange: String,
    @JsonProperty("Currency") val currency: String,
    @JsonProperty("Isin") val isin: String?,
)

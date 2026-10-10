package com.fisa.indice.etf.config

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "etf.catalog")
data class EtfCatalogProperties(
    val selectedIsins: Set<String>,
)

package com.fisa.indice.etf.mappers

import com.fisa.indice.common.mappers.toDto
import com.fisa.indice.etf.dtos.responses.EodhdSymbolDto
import com.fisa.indice.etf.dtos.responses.EtfCatalogResponseDto
import com.fisa.indice.etf.dtos.responses.EtfResponseDto
import com.fisa.indice.etf.entities.EtfEntity
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.RetrievedEtfCatalog
import java.time.Instant

fun EtfEntity.toModel(): Etf = Etf(
    id = id,
    isin = isin,
    ticker = ticker,
    exchange = exchange,
    name = name,
    currency = currency,
    fetchedAt = fetchedAt,
)

fun Etf.toEntity(): EtfEntity = EtfEntity(
    id = id,
    isin = isin,
    ticker = ticker,
    exchange = exchange,
    name = name,
    currency = currency,
    fetchedAt = fetchedAt,
)

fun Etf.toDto(): EtfResponseDto = EtfResponseDto(
    isin = isin,
    ticker = ticker,
    exchange = exchange,
    name = name,
    currency = currency,
)

fun RetrievedEtfCatalog.toDto(): EtfCatalogResponseDto = EtfCatalogResponseDto(
    etfs = etfs.toDto { it.toDto() },
    fetchedAt = lastSynchronizedAt,
    stale = stale,
)

fun EodhdSymbolDto.toModelOrNull(fetchedAt: Instant): Etf? =
    if (isin.isNullOrBlank()) null
    else Etf(
        isin = isin,
        ticker = code,
        exchange = exchange,
        name = name,
        currency = currency,
        fetchedAt = fetchedAt,
    )

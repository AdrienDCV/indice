package com.fisa.indice.etf.mappers

import com.fisa.indice.common.mappers.toDto
import com.fisa.indice.etf.dtos.responses.EtfCatalogResponseDto
import com.fisa.indice.etf.dtos.responses.EtfResponseDto
import com.fisa.indice.etf.dtos.twelvedata.TwelveDataEtfDto
import com.fisa.indice.etf.entities.EtfEntity
import com.fisa.indice.etf.models.Etf
import com.fisa.indice.etf.models.RetrievedEtfCatalog
import java.time.Instant

fun EtfEntity.toModel(favourite: Boolean = false): Etf = Etf(
    id = id,
    ticker = ticker,
    exchange = exchange,
    name = name,
    currency = currency,
    fetchedAt = fetchedAt,
    favourite = favourite,
)

fun Etf.toEntity(): EtfEntity = EtfEntity(
    id = id,
    ticker = ticker,
    exchange = exchange,
    name = name,
    currency = currency,
    fetchedAt = fetchedAt,
)

fun Etf.toDto(): EtfResponseDto = EtfResponseDto(
    ticker = ticker,
    exchange = exchange,
    name = name,
    currency = currency,
    favourite = favourite,
    leveragedOrInverse = isLeveragedOrInverse(),
)

fun RetrievedEtfCatalog.toDto(): EtfCatalogResponseDto = EtfCatalogResponseDto(
    etfs = etfs.toDto { it.toDto() },
    fetchedAt = lastSynchronizedAt,
    stale = stale,
)

fun TwelveDataEtfDto.toModel(fetchedAt: Instant): Etf = Etf(
    ticker = symbol,
    exchange = exchange,
    name = name,
    currency = currency,
    fetchedAt = fetchedAt,
)

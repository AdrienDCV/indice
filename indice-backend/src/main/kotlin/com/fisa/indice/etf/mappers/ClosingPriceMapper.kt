package com.fisa.indice.etf.mappers

import com.fisa.indice.etf.dtos.twelvedata.TwelveDataPriceDto
import com.fisa.indice.etf.entities.EtfClosingPriceEntity
import com.fisa.indice.etf.models.ClosingPrice
import java.time.Instant
import java.util.UUID

fun TwelveDataPriceDto.toModel(): ClosingPrice = ClosingPrice(
    date = datetime,
    adjustedClose = close,
)

fun EtfClosingPriceEntity.toModel(): ClosingPrice = ClosingPrice(
    date = tradingDate,
    adjustedClose = adjustedClose,
)

fun ClosingPrice.toEntity(etfId: UUID, fetchedAt: Instant): EtfClosingPriceEntity = EtfClosingPriceEntity(
    etfId = etfId,
    tradingDate = date,
    adjustedClose = adjustedClose,
    fetchedAt = fetchedAt,
)

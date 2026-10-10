package com.fisa.indice.etf.dtos.responses

import com.fisa.indice.common.dtos.responses.PageResponseDto
import java.time.Instant

data class EtfCatalogResponseDto(
    val etfs: PageResponseDto<EtfResponseDto>,
    val fetchedAt: Instant?,
    val stale: Boolean,
)

package com.fisa.indice.resource.dtos.responses

import com.fisa.indice.resource.models.MediaType

data class MediaResponseDto(
    val url: String,
    val type: MediaType,
)

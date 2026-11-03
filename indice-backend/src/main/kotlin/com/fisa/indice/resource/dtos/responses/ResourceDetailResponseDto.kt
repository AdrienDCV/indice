package com.fisa.indice.resource.dtos.responses

import com.fisa.indice.resource.models.ResourceLevel
import com.fisa.indice.resource.models.ResourceType
import java.util.UUID

data class ResourceDetailResponseDto(
    val id: UUID,
    val title: String,
    val description: String,
    val content: String,
    val type: ResourceType,
    val durationMinutes: Int,
    val level: ResourceLevel,
    val media: MediaResponseDto?,
    val favourite: Boolean,
)

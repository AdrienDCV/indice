package com.fisa.indice.resource.mappers

import com.fisa.indice.resource.dtos.responses.MediaResponseDto
import com.fisa.indice.resource.dtos.responses.ResourceDetailResponseDto
import com.fisa.indice.resource.dtos.responses.ResourceResponseDto
import com.fisa.indice.resource.entities.ResourceEntity
import com.fisa.indice.resource.models.Media
import com.fisa.indice.resource.models.RessourcePedagogique

fun ResourceEntity.toModel(favourite: Boolean = false): RessourcePedagogique = RessourcePedagogique(
    id = id,
    title = title,
    description = description,
    content = content,
    type = type,
    durationMinutes = durationMinutes,
    level = level,
    media = mediaUrl?.let(::Media),
    favourite = favourite,
)

fun RessourcePedagogique.toDto(): ResourceResponseDto = ResourceResponseDto(
    id = id,
    title = title,
    description = description,
    type = type,
    durationMinutes = durationMinutes,
    level = level,
    media = media?.toDto(),
    favourite = favourite,
)

fun RessourcePedagogique.toDetailDto(): ResourceDetailResponseDto = ResourceDetailResponseDto(
    id = id,
    title = title,
    description = description,
    content = content,
    type = type,
    durationMinutes = durationMinutes,
    level = level,
    media = media?.toDto(),
    favourite = favourite,
)

fun Media.toDto(): MediaResponseDto = MediaResponseDto(url = url, type = type)

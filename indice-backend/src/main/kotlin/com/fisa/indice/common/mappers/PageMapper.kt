package com.fisa.indice.common.mappers

import com.fisa.indice.common.dtos.responses.PageResponseDto
import org.springframework.data.domain.Page

fun <T : Any, R> Page<T>.toDto(transform: (T) -> R): PageResponseDto<R> = PageResponseDto(
    content = content.map(transform),
    page = number,
    size = size,
    totalElements = totalElements,
    totalPages = totalPages,
)

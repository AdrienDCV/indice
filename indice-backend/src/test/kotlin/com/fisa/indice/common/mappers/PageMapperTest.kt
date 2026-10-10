package com.fisa.indice.common.mappers

import com.fisa.indice.common.dtos.responses.PageResponseDto
import org.junit.jupiter.api.Test
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import kotlin.test.assertEquals

class PageMapperTest {

    @Test
    fun `should map page content and pagination metadata`() {
        // Given
        val page = PageImpl(listOf(1, 2), PageRequest.of(2, 2), 7)

        // When
        val dto = page.toDto { "item-$it" }

        // Then
        assertEquals(PageResponseDto(listOf("item-1", "item-2"), page = 2, size = 2, totalElements = 7, totalPages = 4), dto)
    }
}

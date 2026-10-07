package com.fisa.indice.common.controllers

import com.fisa.indice.common.dtos.responses.ErrorResponseDto
import com.fisa.indice.common.exceptions.BusinessException
import io.mockk.every
import io.mockk.mockk
import org.springframework.data.core.PropertyReferenceException
import org.junit.jupiter.api.Test
import org.springframework.http.HttpStatus
import org.springframework.validation.ObjectError
import org.springframework.web.bind.MethodArgumentNotValidException
import kotlin.test.assertEquals

class ExceptionControllerTest {

    private val exceptionController = ExceptionController()

    private class TestNotFoundException : BusinessException("error.tests.not-found", HttpStatus.NOT_FOUND)

    @Test
    fun `should return business exception status and message key`() {
        // When
        val response = exceptionController.handleBusinessException(TestNotFoundException())

        // Then
        assertEquals(HttpStatus.NOT_FOUND, response.statusCode)
        assertEquals(listOf(ErrorResponseDto("Not Found", "error.tests.not-found")), response.body)
    }

    @Test
    fun `should return bad request with one error per validation failure`() {
        // Given
        val exception = mockk<MethodArgumentNotValidException> {
            every { bindingResult.allErrors } returns listOf(
                ObjectError("request", "error.etfs.isin-required"),
                ObjectError("request", "error.etfs.name-required"),
            )
        }

        // When
        val response = exceptionController.handleValidationException(exception)

        // Then
        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals(
            listOf(
                ErrorResponseDto("Bad Request", "error.etfs.isin-required"),
                ErrorResponseDto("Bad Request", "error.etfs.name-required"),
            ),
            response.body,
        )
    }

    @Test
    fun `should return bad request without exposing entity details when sort property is unknown`() {
        // When
        val response = exceptionController.handleInvalidSortException(mockk<PropertyReferenceException>())

        // Then
        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals(listOf(ErrorResponseDto("Bad Request", "error.pagination.invalid-sort")), response.body)
    }

    @Test
    fun `should hide technical details of unexpected exceptions`() {
        // When
        val response = exceptionController.handleUnexpectedException(IllegalStateException("SQL error on table etf"))

        // Then
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.statusCode)
        assertEquals(listOf(ErrorResponseDto("Internal Server Error", "error.unexpected")), response.body)
    }
}

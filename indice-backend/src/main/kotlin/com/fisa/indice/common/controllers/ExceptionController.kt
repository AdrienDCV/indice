package com.fisa.indice.common.controllers

import com.fisa.indice.common.dtos.responses.ErrorResponseDto
import com.fisa.indice.common.exceptions.BusinessException
import org.slf4j.LoggerFactory
import org.springframework.data.core.PropertyReferenceException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class ExceptionController {

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationException(exception: MethodArgumentNotValidException): ResponseEntity<List<ErrorResponseDto>> {
        val errors = exception.bindingResult.allErrors.map {
            ErrorResponseDto(error = HttpStatus.BAD_REQUEST.reasonPhrase, message = it.defaultMessage)
        }
        return ResponseEntity(errors, HttpStatus.BAD_REQUEST)
    }

    @ExceptionHandler(PropertyReferenceException::class)
    fun handleInvalidSortException(exception: PropertyReferenceException): ResponseEntity<List<ErrorResponseDto>> {
        val error = ErrorResponseDto(error = HttpStatus.BAD_REQUEST.reasonPhrase, message = INVALID_SORT_MESSAGE)
        return ResponseEntity(listOf(error), HttpStatus.BAD_REQUEST)
    }

    @ExceptionHandler(BusinessException::class)
    fun handleBusinessException(exception: BusinessException): ResponseEntity<List<ErrorResponseDto>> {
        val error = ErrorResponseDto(error = exception.status.reasonPhrase, message = exception.message)
        return ResponseEntity(listOf(error), exception.status)
    }

    @ExceptionHandler(Exception::class)
    fun handleUnexpectedException(exception: Exception): ResponseEntity<List<ErrorResponseDto>> {
        logger.error("Erreur inattendue", exception)
        val error = ErrorResponseDto(error = HttpStatus.INTERNAL_SERVER_ERROR.reasonPhrase, message = UNEXPECTED_ERROR_MESSAGE)
        return ResponseEntity(listOf(error), HttpStatus.INTERNAL_SERVER_ERROR)
    }

    companion object {
        private const val INVALID_SORT_MESSAGE = "error.pagination.invalid-sort"
        private const val UNEXPECTED_ERROR_MESSAGE = "error.unexpected"
        private val logger = LoggerFactory.getLogger(ExceptionController::class.java)
    }
}

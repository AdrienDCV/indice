package com.fisa.indice.common.exceptions

import org.springframework.http.HttpStatus

open class BusinessException(
    message: String = DEFAULT_MESSAGE,
    val status: HttpStatus = DEFAULT_STATUS,
) : RuntimeException(message) {

    companion object {
        private const val DEFAULT_MESSAGE = "error.business.default-message"
        val DEFAULT_STATUS = HttpStatus.INTERNAL_SERVER_ERROR
    }
}

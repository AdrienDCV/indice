package com.fisa.indice.resource.exceptions

import com.fisa.indice.common.exceptions.BusinessException
import org.springframework.http.HttpStatus

class ResourceNotFoundException(
    message: String = DEFAULT_MESSAGE,
) : BusinessException(message, DEFAULT_STATUS) {

    companion object {
        private const val DEFAULT_MESSAGE = "error.resources.resource-not-found"
        val DEFAULT_STATUS = HttpStatus.NOT_FOUND
    }
}

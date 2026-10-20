package com.fisa.indice.etf.exceptions

import com.fisa.indice.common.exceptions.BusinessException
import org.springframework.http.HttpStatus

class EtfNotFoundException(
    message: String = DEFAULT_MESSAGE,
) : BusinessException(message, DEFAULT_STATUS) {

    companion object {
        private const val DEFAULT_MESSAGE = "error.etfs.etf-not-found"
        val DEFAULT_STATUS = HttpStatus.NOT_FOUND
    }
}

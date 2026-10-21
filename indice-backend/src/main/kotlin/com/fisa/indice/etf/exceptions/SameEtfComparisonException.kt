package com.fisa.indice.etf.exceptions

import com.fisa.indice.common.exceptions.BusinessException
import org.springframework.http.HttpStatus

class SameEtfComparisonException(
    message: String = DEFAULT_MESSAGE,
) : BusinessException(message, DEFAULT_STATUS) {

    companion object {
        private const val DEFAULT_MESSAGE = "error.etfs.same-etf-comparison"
        val DEFAULT_STATUS = HttpStatus.BAD_REQUEST
    }
}

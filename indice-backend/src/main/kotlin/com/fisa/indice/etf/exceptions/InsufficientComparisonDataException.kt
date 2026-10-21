package com.fisa.indice.etf.exceptions

import com.fisa.indice.common.exceptions.BusinessException
import org.springframework.http.HttpStatus

class InsufficientComparisonDataException(
    message: String,
) : BusinessException(message, DEFAULT_STATUS) {

    companion object {
        const val ETF_A = "error.etfs.etf-a-insufficient-data"
        const val ETF_B = "error.etfs.etf-b-insufficient-data"
        const val BOTH_ETFS = "error.etfs.etfs-insufficient-data"
        val DEFAULT_STATUS = HttpStatus.UNPROCESSABLE_CONTENT
    }
}

package com.fisa.indice.etf.exceptions

class EodhdDataUnavailableException(cause: Throwable? = null) :
    RuntimeException("EODHD data is unavailable", cause)

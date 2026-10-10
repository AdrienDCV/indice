package com.fisa.indice.etf.clients

import com.fisa.indice.etf.dtos.responses.EodhdSymbolDto
import com.fisa.indice.etf.exceptions.EodhdDataUnavailableException
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component
import org.springframework.web.client.RestClient
import org.springframework.web.client.RestClientException
import org.springframework.web.client.body

@Component
class EodhdClient(
    restClientBuilder: RestClient.Builder,
    @Value("\${eodhd.base-url}") baseUrl: String,
    @Value("\${eodhd.api-token}") private val apiToken: String,
) {
    private val restClient = restClientBuilder.baseUrl(baseUrl).build()

    fun fetchEtfs(exchange: String): List<EodhdSymbolDto> {
        logger.info("Appel EODHD pour la place {}", exchange)
        val symbols = try {
            restClient.get()
                .uri("/exchange-symbol-list/{exchange}?api_token={token}&fmt=json&type=etf", exchange, apiToken)
                .retrieve()
                .body<List<EodhdSymbolDto>>()
        } catch (exception: RestClientException) {
            throw EodhdDataUnavailableException(exception)
        }
        if (symbols.isNullOrEmpty()) throw EodhdDataUnavailableException()
        return symbols
    }

    companion object {
        private val logger = LoggerFactory.getLogger(EodhdClient::class.java)
    }
}

package com.fisa.indice.etf.clients

import com.fisa.indice.etf.dtos.responses.TwelveDataEtfDto
import com.fisa.indice.etf.dtos.responses.TwelveDataEtfsDto
import com.fisa.indice.etf.exceptions.TwelveDataUnavailableException
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.HttpHeaders
import org.springframework.stereotype.Component
import org.springframework.web.client.RestClient
import org.springframework.web.client.RestClientException
import org.springframework.web.client.body

@Component
class TwelveDataClient(
    restClientBuilder: RestClient.Builder,
    @Value("\${twelvedata.base-url}") baseUrl: String,
    @Value("\${twelvedata.api-token}") apiToken: String,
) {
    private val restClient = restClientBuilder
        .baseUrl(baseUrl)
        .defaultHeader(HttpHeaders.AUTHORIZATION, "apikey $apiToken")
        .build()

    fun fetchEtfs(country: String): List<TwelveDataEtfDto> {
        logger.info("Appel Twelve Data pour l'annuaire des ETF ({})", country)
        val response = try {
            restClient.get()
                .uri("/etfs?country={country}", country)
                .retrieve()
                .body<TwelveDataEtfsDto>()
        } catch (exception: RestClientException) {
            throw TwelveDataUnavailableException(exception)
        }
        if (response?.status != SUCCESS_STATUS || response.data.isNullOrEmpty()) throw TwelveDataUnavailableException()
        return response.data
    }

    companion object {
        private const val SUCCESS_STATUS = "ok"
        private val logger = LoggerFactory.getLogger(TwelveDataClient::class.java)
    }
}

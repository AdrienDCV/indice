package com.fisa.indice.etf.clients

import com.fisa.indice.etf.dtos.twelvedata.TwelveDataEtfDto
import com.fisa.indice.etf.dtos.twelvedata.TwelveDataEtfsDto
import com.fisa.indice.etf.dtos.twelvedata.TwelveDataPriceDto
import com.fisa.indice.etf.dtos.twelvedata.TwelveDataTimeSeriesDto
import com.fisa.indice.etf.exceptions.TwelveDataUnavailableException
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.HttpHeaders
import org.springframework.stereotype.Component
import org.springframework.web.client.RestClient
import org.springframework.web.client.RestClientException
import org.springframework.web.client.body
import java.time.LocalDate

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

    fun fetchDailyClosingPrices(ticker: String, startDate: LocalDate): List<TwelveDataPriceDto> {
        logger.info("Appel Twelve Data pour les cours de clôture de {}", ticker)
        val response = try {
            restClient.get()
                .uri(
                    "/time_series?symbol={symbol}&interval=1day&start_date={startDate}&adjust=all&order=asc&outputsize={outputSize}",
                    ticker,
                    startDate,
                    MAX_OUTPUT_SIZE,
                )
                .retrieve()
                .body<TwelveDataTimeSeriesDto>()
        } catch (exception: RestClientException) {
            throw TwelveDataUnavailableException(exception)
        }
        if (response?.status != SUCCESS_STATUS || response.values.isNullOrEmpty()) throw TwelveDataUnavailableException()
        return response.values
    }

    companion object {
        private const val SUCCESS_STATUS = "ok"
        private const val MAX_OUTPUT_SIZE = 5000
        private val logger = LoggerFactory.getLogger(TwelveDataClient::class.java)
    }
}

package com.fisa.indice.etf.clients

import com.fisa.indice.etf.dtos.twelvedata.TwelveDataEtfDto
import com.fisa.indice.etf.dtos.twelvedata.TwelveDataPriceDto
import com.fisa.indice.etf.exceptions.TwelveDataUnavailableException
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.core.io.ClassPathResource
import org.springframework.http.HttpHeaders
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.test.web.client.MockRestServiceServer
import org.springframework.test.web.client.match.MockRestRequestMatchers.header
import org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo
import org.springframework.test.web.client.response.MockRestResponseCreators.withStatus
import org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess
import org.springframework.web.client.RestClient
import java.math.BigDecimal
import java.time.LocalDate
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class TwelveDataClientTest {

    private val builder = RestClient.builder()
    private val server = MockRestServiceServer.bindTo(builder).build()
    private val twelveDataClient = TwelveDataClient(builder, BASE_URL, TOKEN)

    private fun expectCall() = server.expect(requestTo("$BASE_URL/etfs?country=United%20States"))

    @Test
    fun `should deserialize twelve data etfs ignoring unknown fields`() {
        // Given
        expectCall().andRespond(withSuccess(ClassPathResource("twelvedata/etfs-united-states.json"), MediaType.APPLICATION_JSON))

        // When
        val etfs = twelveDataClient.fetchEtfs(COUNTRY)

        // Then
        assertEquals(
            listOf(
                TwelveDataEtfDto("SPY", "State Street SPDR S&P 500 ETF Trust", "USD", "NYSE"),
                TwelveDataEtfDto("QQQ", "Invesco QQQ Trust, Series 1", "USD", "NASDAQ"),
            ),
            etfs,
        )
        server.verify()
    }

    @Test
    fun `should send the token in the authorization header`() {
        // Given
        expectCall()
            .andExpect(header(HttpHeaders.AUTHORIZATION, "apikey $TOKEN"))
            .andRespond(withSuccess(ClassPathResource("twelvedata/etfs-united-states.json"), MediaType.APPLICATION_JSON))

        // When
        twelveDataClient.fetchEtfs(COUNTRY)

        // Then
        server.verify()
    }

    @Test
    fun `should throw TwelveDataUnavailableException when twelve data responds with an error status`() {
        expectCall().andRespond(withStatus(HttpStatus.INTERNAL_SERVER_ERROR))

        assertThrows<TwelveDataUnavailableException> { twelveDataClient.fetchEtfs(COUNTRY) }
    }

    @Test
    fun `should throw TwelveDataUnavailableException when twelve data reports an error with a 200 status`() {
        expectCall().andRespond(
            withSuccess("""{"code":429,"message":"You have run out of API credits","status":"error"}""", MediaType.APPLICATION_JSON)
        )

        assertThrows<TwelveDataUnavailableException> { twelveDataClient.fetchEtfs(COUNTRY) }
    }

    @Test
    fun `should throw TwelveDataUnavailableException when twelve data responds with invalid json`() {
        expectCall().andRespond(withSuccess("not json", MediaType.APPLICATION_JSON))

        assertThrows<TwelveDataUnavailableException> { twelveDataClient.fetchEtfs(COUNTRY) }
    }

    @Test
    fun `should throw TwelveDataUnavailableException when twelve data responds with no etf`() {
        expectCall().andRespond(withSuccess("""{"data":[],"count":0,"status":"ok"}""", MediaType.APPLICATION_JSON))

        assertThrows<TwelveDataUnavailableException> { twelveDataClient.fetchEtfs(COUNTRY) }
    }

    @Test
    fun `should not expose the token in the exception message`() {
        // Given
        expectCall().andRespond(withStatus(HttpStatus.UNAUTHORIZED))

        // When
        val exception = assertThrows<TwelveDataUnavailableException> { twelveDataClient.fetchEtfs(COUNTRY) }

        // Then
        assertFalse(exception.message.orEmpty().contains(TOKEN))
    }

    private fun expectTimeSeriesCall() = server.expect(
        requestTo("$BASE_URL/time_series?symbol=SPY&interval=1day&start_date=2021-10-13&adjust=all&order=asc&outputsize=5000")
    )

    @Test
    fun `should deserialize daily closing prices from strings`() {
        // Given
        expectTimeSeriesCall().andRespond(withSuccess(ClassPathResource("twelvedata/time-series-spy.json"), MediaType.APPLICATION_JSON))

        // When
        val prices = twelveDataClient.fetchDailyClosingPrices("SPY", START_DATE)

        // Then
        assertEquals(
            listOf(
                TwelveDataPriceDto(LocalDate.parse("2026-10-15"), BigDecimal("768.010010")),
                TwelveDataPriceDto(LocalDate.parse("2026-10-16"), BigDecimal("763.25")),
            ),
            prices,
        )
        server.verify()
    }

    @Test
    fun `should throw TwelveDataUnavailableException when time series reports an error with a 200 status`() {
        expectTimeSeriesCall().andRespond(
            withSuccess("""{"code":400,"message":"symbol not found","status":"error"}""", MediaType.APPLICATION_JSON)
        )

        assertThrows<TwelveDataUnavailableException> { twelveDataClient.fetchDailyClosingPrices("SPY", START_DATE) }
    }

    @Test
    fun `should throw TwelveDataUnavailableException when time series has no value`() {
        expectTimeSeriesCall().andRespond(withSuccess("""{"values":[],"status":"ok"}""", MediaType.APPLICATION_JSON))

        assertThrows<TwelveDataUnavailableException> { twelveDataClient.fetchDailyClosingPrices("SPY", START_DATE) }
    }

    @Test
    fun `should throw TwelveDataUnavailableException when time series responds with an error status`() {
        expectTimeSeriesCall().andRespond(withStatus(HttpStatus.SERVICE_UNAVAILABLE))

        assertThrows<TwelveDataUnavailableException> { twelveDataClient.fetchDailyClosingPrices("SPY", START_DATE) }
    }

    companion object {
        private const val BASE_URL = "https://twelvedata.test"
        private const val TOKEN = "secret-token"
        private const val COUNTRY = "United States"
        private val START_DATE = LocalDate.parse("2021-10-13")
    }
}

package com.fisa.indice.etf.clients

import com.fisa.indice.etf.dtos.responses.EodhdSymbolDto
import com.fisa.indice.etf.exceptions.EodhdDataUnavailableException
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.core.io.ClassPathResource
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.test.web.client.MockRestServiceServer
import org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo
import org.springframework.test.web.client.response.MockRestResponseCreators.withStatus
import org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess
import org.springframework.web.client.RestClient
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class EodhdClientTest {

    private val builder = RestClient.builder()
    private val server = MockRestServiceServer.bindTo(builder).build()
    private val eodhdClient = EodhdClient(builder, BASE_URL, TOKEN)

    private fun expectCall() = server.expect(
        requestTo("$BASE_URL/exchange-symbol-list/PA?api_token=$TOKEN&fmt=json&type=etf")
    )

    @Test
    fun `should deserialize eodhd response including null isin and unknown fields`() {
        // Given
        expectCall().andRespond(withSuccess(ClassPathResource("eodhd/exchange-symbol-list-pa.json"), MediaType.APPLICATION_JSON))

        // When
        val symbols = eodhdClient.fetchEtfs("PA")

        // Then
        assertEquals(
            listOf(
                EodhdSymbolDto("CW8", "Amundi MSCI World UCITS ETF", "PA", "EUR", "LU1681043599"),
                EodhdSymbolDto("NOISIN", "ETF without ISIN", "PA", "EUR", null),
            ),
            symbols,
        )
        server.verify()
    }

    @Test
    fun `should throw EodhdDataUnavailableException when eodhd responds with an error status`() {
        expectCall().andRespond(withStatus(HttpStatus.INTERNAL_SERVER_ERROR))

        assertThrows<EodhdDataUnavailableException> { eodhdClient.fetchEtfs("PA") }
    }

    @Test
    fun `should throw EodhdDataUnavailableException when eodhd responds with invalid json`() {
        expectCall().andRespond(withSuccess("not json", MediaType.APPLICATION_JSON))

        assertThrows<EodhdDataUnavailableException> { eodhdClient.fetchEtfs("PA") }
    }

    @Test
    fun `should throw EodhdDataUnavailableException when eodhd responds with an empty list`() {
        expectCall().andRespond(withSuccess("[]", MediaType.APPLICATION_JSON))

        assertThrows<EodhdDataUnavailableException> { eodhdClient.fetchEtfs("PA") }
    }

    @Test
    fun `should not expose the token in the exception message`() {
        // Given
        expectCall().andRespond(withStatus(HttpStatus.UNAUTHORIZED))

        // When
        val exception = assertThrows<EodhdDataUnavailableException> { eodhdClient.fetchEtfs("PA") }

        // Then
        assertFalse(exception.message.orEmpty().contains(TOKEN))
    }

    companion object {
        private const val BASE_URL = "https://eodhd.test/api"
        private const val TOKEN = "secret-token"
    }
}

package com.fisa.indice.etf.controllers

import com.fisa.indice.etf.dtos.responses.EtfCatalogResponseDto
import com.fisa.indice.etf.dtos.responses.EtfDetailResponseDto
import com.fisa.indice.etf.mappers.toDto
import com.fisa.indice.etf.services.EtfDetailService
import com.fisa.indice.etf.services.EtfService
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RestController

@RestController
class EtfController(
    private val etfService: EtfService,
    private val etfDetailService: EtfDetailService,
) {

    @GetMapping("/etfs")
    fun retrieveEtfs(@PageableDefault(size = 20, sort = ["name"]) pageable: Pageable): EtfCatalogResponseDto =
        etfService.retrieveEtfs(pageable).toDto()

    @GetMapping("/etfs/{ticker}")
    fun retrieveEtf(@PathVariable ticker: String): EtfDetailResponseDto =
        etfDetailService.retrieveEtf(ticker).toDto()
}

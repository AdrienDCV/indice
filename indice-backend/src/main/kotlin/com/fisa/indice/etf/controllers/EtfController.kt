package com.fisa.indice.etf.controllers

import com.fisa.indice.etf.dtos.responses.EtfCatalogResponseDto
import com.fisa.indice.etf.dtos.responses.EtfComparisonResponseDto
import com.fisa.indice.etf.dtos.responses.EtfDetailResponseDto
import com.fisa.indice.etf.mappers.toDto
import com.fisa.indice.etf.services.EtfComparisonService
import com.fisa.indice.etf.services.EtfDetailService
import com.fisa.indice.etf.services.EtfService
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/etfs")
class EtfController(
    private val etfService: EtfService,
    private val etfDetailService: EtfDetailService,
    private val etfComparisonService: EtfComparisonService,
) {

    @GetMapping
    fun retrieveEtfs(
        @RequestParam search: String?,
        @RequestParam(defaultValue = "false") favourites: Boolean,
        @PageableDefault(size = 20, sort = ["name"]) pageable: Pageable,
    ): EtfCatalogResponseDto =
        etfService.retrieveEtfs(pageable, search, favourites).toDto()

    @GetMapping("/compare")
    fun compareEtfs(@RequestParam etfA: String, @RequestParam etfB: String): EtfComparisonResponseDto =
        etfComparisonService.compare(etfA, etfB).toDto()

    @GetMapping("/{ticker}")
    fun retrieveEtf(@PathVariable ticker: String): EtfDetailResponseDto =
        etfDetailService.retrieveEtf(ticker).toDto()

    @PutMapping("/{ticker}/favourite")
    fun addFavourite(@PathVariable ticker: String): EtfDetailResponseDto =
        etfDetailService.addFavourite(ticker).toDto()

    @DeleteMapping("/{ticker}/favourite")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun removeFavourite(@PathVariable ticker: String) = etfDetailService.removeFavourite(ticker)
}

package com.fisa.indice.etf.controllers

import com.fisa.indice.etf.dtos.responses.EtfCatalogResponseDto
import com.fisa.indice.etf.dtos.responses.EtfDetailResponseDto
import com.fisa.indice.etf.mappers.toDto
import com.fisa.indice.etf.services.EtfDetailService
import com.fisa.indice.etf.services.EtfService
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
class EtfController(
    private val etfService: EtfService,
    private val etfDetailService: EtfDetailService,
) {

    @GetMapping("/etfs")
    fun retrieveEtfs(
        @RequestParam search: String?,
        @RequestParam(defaultValue = "false") favourites: Boolean,
        @PageableDefault(size = 20, sort = ["name"]) pageable: Pageable,
    ): EtfCatalogResponseDto =
        etfService.retrieveEtfs(pageable, search, favourites).toDto()

    @GetMapping("/etfs/{ticker}")
    fun retrieveEtf(@PathVariable ticker: String): EtfDetailResponseDto =
        etfDetailService.retrieveEtf(ticker).toDto()

    @PutMapping("/etfs/{ticker}/favourite")
    fun addFavourite(@PathVariable ticker: String): ResponseEntity<Unit> =
        if (etfService.addFavourite(ticker)) ResponseEntity.status(HttpStatus.CREATED).build() else ResponseEntity.ok().build()

    @DeleteMapping("/etfs/{ticker}/favourite")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun removeFavourite(@PathVariable ticker: String) = etfService.removeFavourite(ticker)
}

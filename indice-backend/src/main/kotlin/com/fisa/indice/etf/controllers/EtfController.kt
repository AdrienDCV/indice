package com.fisa.indice.etf.controllers

import com.fisa.indice.etf.dtos.responses.EtfCatalogResponseDto
import com.fisa.indice.etf.mappers.toDto
import com.fisa.indice.etf.services.EtfService
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
class EtfController(
    private val etfService: EtfService
) {

    @GetMapping("/etfs")
    fun retrieveEtfs(@PageableDefault(size = 20, sort = ["name"]) pageable: Pageable): EtfCatalogResponseDto =
        etfService.retrieveEtfs(pageable).toDto()
}

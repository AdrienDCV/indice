package com.fisa.indice.etf.controllers

import com.fisa.indice.etf.dtos.responses.EtfComparisonResponseDto
import com.fisa.indice.etf.mappers.toDto
import com.fisa.indice.etf.services.EtfComparisonService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
class EtfComparisonController(
    private val etfComparisonService: EtfComparisonService,
) {

    @GetMapping("/etfs/compare")
    fun compareEtfs(@RequestParam etfA: String, @RequestParam etfB: String): EtfComparisonResponseDto =
        etfComparisonService.compare(etfA, etfB).toDto()
}

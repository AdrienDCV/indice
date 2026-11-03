package com.fisa.indice.resource.controllers

import com.fisa.indice.common.dtos.responses.PageResponseDto
import com.fisa.indice.common.mappers.toDto
import com.fisa.indice.resource.dtos.responses.ResourceDetailResponseDto
import com.fisa.indice.resource.dtos.responses.ResourceResponseDto
import com.fisa.indice.resource.mappers.toDetailDto
import com.fisa.indice.resource.mappers.toDto
import com.fisa.indice.resource.models.ResourceLevel
import com.fisa.indice.resource.services.ResourceService
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
class ResourceController(
    private val resourceService: ResourceService,
) {

    @GetMapping("/resources")
    fun retrieveResources(
        @RequestParam search: String?,
        @RequestParam levels: Set<ResourceLevel>?,
        @RequestParam(defaultValue = "false") favourites: Boolean,
        @PageableDefault(size = 20, sort = ["title"]) pageable: Pageable,
    ): PageResponseDto<ResourceResponseDto> =
        resourceService.retrieveResources(pageable, search, levels.orEmpty(), favourites).toDto { it.toDto() }

    @GetMapping("/resources/{id}")
    fun retrieveResource(@PathVariable id: UUID): ResourceDetailResponseDto =
        resourceService.retrieveResource(id).toDetailDto()

    @PutMapping("/resources/{id}/favourite")
    fun addFavourite(@PathVariable id: UUID): ResourceDetailResponseDto =
        resourceService.addFavourite(id).toDetailDto()

    @DeleteMapping("/resources/{id}/favourite")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun removeFavourite(@PathVariable id: UUID) = resourceService.removeFavourite(id)
}

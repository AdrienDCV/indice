package com.fisa.indice.resource.services

import com.fisa.indice.resource.entities.FavouriteResourceEntity
import com.fisa.indice.resource.entities.ResourceEntity
import com.fisa.indice.resource.exceptions.ResourceNotFoundException
import com.fisa.indice.resource.mappers.toModel
import com.fisa.indice.resource.models.ResourceLevel
import com.fisa.indice.resource.models.RessourcePedagogique
import com.fisa.indice.resource.repositories.FavouriteResourceRepository
import com.fisa.indice.resource.repositories.ResourceRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class ResourceService(
    private val resourceRepository: ResourceRepository,
    private val favouriteResourceRepository: FavouriteResourceRepository,
) {

    @Transactional(readOnly = true)
    fun retrieveResources(
        pageable: Pageable,
        search: String?,
        levels: Set<ResourceLevel>,
        favouritesOnly: Boolean,
    ): Page<RessourcePedagogique> {
        val normalizedSearch = search?.trim()?.lowercase().orEmpty()
        val page = resourceRepository.findInCatalog(normalizedSearch, levels.ifEmpty { ResourceLevel.entries.toSet() }, favouritesOnly, pageable)
        val favouriteIds = favouriteResourceRepository.findAllById(page.content.map { it.id }).mapTo(HashSet()) { it.resourceId }
        return page.map { it.toModel(favourite = it.id in favouriteIds) }
    }

    @Transactional(readOnly = true)
    fun retrieveResource(id: UUID): RessourcePedagogique =
        findResource(id).toModel(favourite = favouriteResourceRepository.existsById(id))

    @Transactional
    fun addFavourite(id: UUID): RessourcePedagogique {
        val resource = findResource(id)
        if (!favouriteResourceRepository.existsById(id)) favouriteResourceRepository.save(FavouriteResourceEntity(id))
        return resource.toModel(favourite = true)
    }

    @Transactional
    fun removeFavourite(id: UUID) {
        favouriteResourceRepository.deleteById(id)
    }

    private fun findResource(id: UUID): ResourceEntity =
        resourceRepository.findByIdOrNull(id) ?: throw ResourceNotFoundException()
}

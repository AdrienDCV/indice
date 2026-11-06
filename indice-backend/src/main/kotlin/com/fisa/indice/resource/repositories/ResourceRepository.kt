package com.fisa.indice.resource.repositories

import com.fisa.indice.resource.entities.ResourceEntity
import com.fisa.indice.resource.models.ResourceLevel
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.util.UUID

interface ResourceRepository : JpaRepository<ResourceEntity, UUID> {

    @Query(
        """
        select r from ResourceEntity r
        where (lower(r.title) like concat('%', :search, '%') or lower(r.description) like concat('%', :search, '%'))
          and r.level in :levels
          and (:favouritesOnly = false or exists (select f from FavouriteResourceEntity f where f.resourceId = r.id))
        """
    )
    fun findInCatalog(search: String, levels: Collection<ResourceLevel>, favouritesOnly: Boolean, pageable: Pageable): Page<ResourceEntity>
}

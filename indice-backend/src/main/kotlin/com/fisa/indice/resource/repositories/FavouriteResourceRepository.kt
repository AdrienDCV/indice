package com.fisa.indice.resource.repositories

import com.fisa.indice.resource.entities.FavouriteResourceEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface FavouriteResourceRepository : JpaRepository<FavouriteResourceEntity, UUID>

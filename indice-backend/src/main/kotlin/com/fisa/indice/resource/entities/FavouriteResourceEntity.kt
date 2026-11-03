package com.fisa.indice.resource.entities

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.util.UUID

@Entity
@Table(name = "favourite_resource")
class FavouriteResourceEntity(
    @Id
    @Column(name = "resource_id")
    val resourceId: UUID,
) {
    override fun equals(other: Any?): Boolean =
        this === other || (other is FavouriteResourceEntity && resourceId == other.resourceId)

    override fun hashCode(): Int = resourceId.hashCode()
}

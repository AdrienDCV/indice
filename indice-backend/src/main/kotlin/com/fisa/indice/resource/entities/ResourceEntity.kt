package com.fisa.indice.resource.entities

import com.fisa.indice.resource.models.ResourceLevel
import com.fisa.indice.resource.models.ResourceType
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.util.UUID

@Entity
@Table(name = "resource")
class ResourceEntity(
    @Id
    val id: UUID,

    @Column(nullable = false)
    val title: String,

    @Column(nullable = false)
    val description: String,

    @Column(nullable = false, columnDefinition = "text")
    val content: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val type: ResourceType,

    @Column(name = "duration_minutes", nullable = false)
    val durationMinutes: Int,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val level: ResourceLevel,

    @Column(name = "media_url")
    val mediaUrl: String?,
) {
    override fun equals(other: Any?): Boolean = this === other || (other is ResourceEntity && id == other.id)

    override fun hashCode(): Int = id.hashCode()
}

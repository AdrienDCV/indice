package com.fisa.indice.resource.models

import java.util.UUID

data class RessourcePedagogique(
    val title: String,
    val description: String,
    val content: String,
    val type: ResourceType,
    val durationMinutes: Int,
    val level: ResourceLevel,
    val media: Media?,
    val favourite: Boolean = false,
    val id: UUID = UUID.randomUUID(),
) {
    init {
        require(title.isNotBlank()) { "A resource must have a title" }
        require(durationMinutes > 0) { "A resource must have a positive duration" }
        require(type != ResourceType.VIDEO || media?.type == MediaType.VIDEO) { "A video resource must have a video media" }
    }
}

package com.fisa.indice.etf.entities

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "etf")
class EtfEntity(
    @Id
    val id: UUID,

    @Column(nullable = false, unique = true)
    val isin: String,

    @Column(nullable = false)
    var ticker: String,

    @Column(nullable = false)
    var exchange: String,

    @Column(nullable = false)
    var name: String,

    @Column(nullable = false)
    var currency: String,

    @Column(name = "fetched_at", nullable = false)
    var fetchedAt: Instant,
) {
    override fun equals(other: Any?): Boolean = this === other || (other is EtfEntity && id == other.id)

    override fun hashCode(): Int = id.hashCode()
}

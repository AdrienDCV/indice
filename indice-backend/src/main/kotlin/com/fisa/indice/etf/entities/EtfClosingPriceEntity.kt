package com.fisa.indice.etf.entities

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.springframework.data.domain.Persistable
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

@Entity
@Table(name = "etf_closing_price")
class EtfClosingPriceEntity(
    @Id
    private val id: UUID,

    @Column(name = "etf_id", nullable = false)
    val etfId: UUID,

    @Column(name = "trading_date", nullable = false)
    val tradingDate: LocalDate,

    @Column(name = "adjusted_close", nullable = false, precision = 19, scale = 6)
    val adjustedClose: BigDecimal,

    @Column(name = "fetched_at", nullable = false)
    val fetchedAt: Instant,
) : Persistable<UUID> {

    override fun getId(): UUID = id

    // Les cours sont toujours insérés, jamais mis à jour : évite un SELECT par ligne lors du saveAll
    override fun isNew(): Boolean = true

    override fun equals(other: Any?): Boolean = this === other || (other is EtfClosingPriceEntity && id == other.id)

    override fun hashCode(): Int = id.hashCode()
}

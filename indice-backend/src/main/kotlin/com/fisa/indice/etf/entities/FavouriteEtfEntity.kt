package com.fisa.indice.etf.entities

import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table

@Entity
@Table(name = "favourite_etf")
class FavouriteEtfEntity(
    @Id
    val ticker: String,
) {
    override fun equals(other: Any?): Boolean = this === other || (other is FavouriteEtfEntity && ticker == other.ticker)

    override fun hashCode(): Int = ticker.hashCode()
}

package com.fisa.indice.etf.repositories

import com.fisa.indice.etf.entities.FavouriteEtfEntity
import org.springframework.data.jpa.repository.JpaRepository

interface FavouriteEtfRepository : JpaRepository<FavouriteEtfEntity, String>

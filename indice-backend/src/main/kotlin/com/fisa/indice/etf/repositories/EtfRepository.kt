package com.fisa.indice.etf.repositories

import com.fisa.indice.etf.entities.EtfEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface EtfRepository : JpaRepository<EtfEntity, UUID> {

    fun findFirstByOrderByFetchedAtDesc(): EtfEntity?
}

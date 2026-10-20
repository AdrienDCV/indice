package com.fisa.indice.etf.repositories

import com.fisa.indice.etf.entities.EtfClosingPriceEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface EtfClosingPriceRepository : JpaRepository<EtfClosingPriceEntity, UUID> {

    fun findAllByEtfIdOrderByTradingDateAsc(etfId: UUID): List<EtfClosingPriceEntity>

    fun findFirstByEtfIdOrderByFetchedAtDesc(etfId: UUID): EtfClosingPriceEntity?

    @Modifying
    @Query("delete from EtfClosingPriceEntity c where c.etfId = :etfId")
    fun deleteAllByEtfId(@Param("etfId") etfId: UUID): Int
}

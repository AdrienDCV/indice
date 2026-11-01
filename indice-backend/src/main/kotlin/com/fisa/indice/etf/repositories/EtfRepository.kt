package com.fisa.indice.etf.repositories

import com.fisa.indice.etf.entities.EtfEntity
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.util.UUID

interface EtfRepository : JpaRepository<EtfEntity, UUID> {

    fun findFirstByOrderByFetchedAtDesc(): EtfEntity?

    fun findByTicker(ticker: String): EtfEntity?

    @Query(
        """
        select e from EtfEntity e
        where (lower(e.ticker) like concat(:search, '%') or lower(e.name) like concat('%', :search, '%'))
          and (:favouritesOnly = false or exists (select f from FavouriteEtfEntity f where f.ticker = e.ticker))
        """
    )
    fun findInCatalog(search: String, favouritesOnly: Boolean, pageable: Pageable): Page<EtfEntity>
}

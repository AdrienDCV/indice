package com.fisa.indice.etf.models

import org.springframework.data.domain.Page
import java.time.Instant

data class RetrievedEtfCatalog(
    val etfs: Page<Etf>,
    val lastSynchronizedAt: Instant?,
    val stale: Boolean,
)

package com.fisa.indice.etf.models

import com.fisa.indice.etf.exceptions.InsufficientComparisonDataException
import java.math.BigDecimal

data class EtfComparison(
    val etfA: ComparedEtf,
    val etfB: ComparedEtf,
    val commonPeriod: DateRange,
    val correlation: BigDecimal?,
) {
    companion object {

        /**
         * Compare deux ETF sur leur période commune. Chaque historique doit couvrir au moins un an avant
         * la fin de cette période (la plus ancienne des deux dernières clôtures), sinon la comparaison
         * est impossible et l'exception désigne l'ETF A, l'ETF B ou les deux.
         */
        fun between(
            etfA: Etf,
            etfAPrices: EtfPrices,
            etfB: Etf,
            etfBPrices: EtfPrices,
        ): EtfComparison {
            val periodEnd = listOfNotNull(etfAPrices.history, etfBPrices.history).minOfOrNull { it.lastClose().date }
            val historyA = periodEnd?.let { end -> etfAPrices.history?.takeIf { it.coversOneYearUntil(end) } }
            val historyB = periodEnd?.let { end -> etfBPrices.history?.takeIf { it.coversOneYearUntil(end) } }
            if (historyA == null || historyB == null) throw insufficientData(etfAMissing = historyA == null, etfBMissing = historyB == null)

            val (commonA, commonB) = historyA.commonPeriodWith(historyB) ?: throw insufficientData(etfAMissing = true, etfBMissing = true)
            return EtfComparison(
                etfA = compared(etfA, commonA, etfAPrices),
                etfB = compared(etfB, commonB, etfBPrices),
                commonPeriod = DateRange(commonA.historyStartDate(), commonA.lastClose().date),
                correlation = commonA.correlationWith(commonB),
            )
        }

        private fun compared(etf: Etf, commonHistory: ClosingPriceHistory, prices: EtfPrices) =
            ComparedEtf(etf, commonHistory.performance(), commonHistory.pricePoints(), prices.fetchedAt, prices.stale)

        private fun insufficientData(etfAMissing: Boolean, etfBMissing: Boolean) = InsufficientComparisonDataException(
            when {
                etfAMissing && etfBMissing -> InsufficientComparisonDataException.BOTH_ETFS
                etfAMissing -> InsufficientComparisonDataException.ETF_A
                else -> InsufficientComparisonDataException.ETF_B
            }
        )
    }
}

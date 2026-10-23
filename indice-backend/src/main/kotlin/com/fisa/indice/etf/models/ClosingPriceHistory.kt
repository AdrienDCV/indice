package com.fisa.indice.etf.models

import java.math.BigDecimal
import java.math.MathContext
import java.math.RoundingMode
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import kotlin.math.pow

/**
 * Historique des clôtures ajustées d'un ETF (dividendes réinvestis), trié par date croissante.
 * Porte tous les calculs de la fiche détail et de la comparaison.
 *
 * Vocabulaire utilisé dans cette classe :
 * - **clôture** : dernier cours d'un jour de bourse ;
 * - **croissance** : `dernière clôture / première clôture` (1,20 signifie que le cours a gagné 20 %) ;
 * - **rendement** : `croissance − 1`, exprimé en fraction (0,20 = +20 %, −0,10 = −10 %) ;
 * - **rendement journalier** : rendement d'un jour de bourse au suivant.
 *
 * Les taux sont arrondis à 4 décimales (0,1234 = 12,34 %) et les prix à 2 décimales, uniquement dans
 * les résultats : les calculs intermédiaires gardent toute leur précision.
 */
data class ClosingPriceHistory(val prices: List<ClosingPrice>) {
    init {
        require(prices.isNotEmpty()) { "A closing price history cannot be empty" }
        require(prices.zipWithNext().all { (previous, next) -> previous.date < next.date }) {
            "Closing prices must be sorted by strictly increasing date"
        }
    }

    fun lastClose(): ClosingPrice = prices.last()

    fun historyStartDate(): LocalDate = prices.first().date

    /**
     * Rendement sur les N dernières années : `dernière clôture / clôture de référence − 1`, où la clôture
     * de référence est celle d'il y a N ans (ou le jour de bourse précédent si le marché était fermé).
     * `null` si l'historique ne couvre pas N ans.
     */
    fun returnOver(years: Long): BigDecimal? = windowOver(years)?.totalReturn()

    /**
     * Rendement annualisé sur N ans entiers : (1 + rendement sur N ans)^(1/N) − 1.
     * `null` si l'historique ne couvre pas N ans.
     */
    fun annualizedReturnOver(years: Long): BigDecimal? =
        windowOver(years)?.let { annualize(it.growth(), years.toDouble()).rounded() }

    /** Volatilité annualisée (voir [volatility]) sur les N dernières années. `null` si l'historique ne couvre pas N ans. */
    fun volatilityOver(years: Long): BigDecimal? = windowOver(years)?.volatility()

    /** Perte maximale (voir [maxDrawdown]) sur les N dernières années. `null` si l'historique ne couvre pas N ans. */
    fun maxDrawdownOver(years: Long): Drawdown? = windowOver(years)?.maxDrawdown()

    /**
     * Fourchette sur 52 semaines : plus bas et plus haut des clôtures de la dernière année, et position
     * de la dernière clôture dans cette fourchette, de 0 (au plus bas) à 1 (au plus haut) :
     * `(dernière clôture − plus bas) / (plus haut − plus bas)`. Si le cours n'a pas bougé, la position vaut 0,5.
     * `null` si l'historique ne couvre pas un an.
     */
    fun fiftyTwoWeekRange(): PriceRange? {
        val closes = windowOver(1)?.prices?.map { it.adjustedClose } ?: return null
        val low = closes.min()
        val high = closes.max()
        val position = if (high.compareTo(low) == 0) MIDDLE_POSITION
        else (lastClose().adjustedClose - low).divide(high - low, MATH_CONTEXT)
        return PriceRange(low.roundedPrice(), high.roundedPrice(), position.rounded())
    }

    fun pricePoints(): List<PricePoint> {
        val first = prices.first().adjustedClose
        return prices.map {
            PricePoint(
                it.date,
                it.adjustedClose.roundedPrice(),
                (it.adjustedClose.divide(first, MATH_CONTEXT) - BigDecimal.ONE).rounded(),
            )
        }
    }

    fun marketData(): MarketData = MarketData(
        lastClose = lastClose().let { it.copy(adjustedClose = it.adjustedClose.roundedPrice()) },
        historyStartDate = historyStartDate(),
        returnOneYear = returnOver(1),
        returnThreeYears = returnOver(3),
        returnFiveYears = returnOver(5),
        annualizedReturnFiveYears = annualizedReturnOver(5),
        volatilityOneYear = volatilityOver(1),
        maxDrawdownFiveYears = maxDrawdownOver(5),
        fiftyTwoWeekRange = fiftyTwoWeekRange(),
        pricePoints = pricePoints(),
    )

    /**
     * Vrai si l'historique contient une clôture au moins un an avant [date] : il suffit alors
     * pour calculer des indicateurs annualisés jusqu'à cette date (même règle que la clôture de référence).
     */
    fun coversOneYearUntil(date: LocalDate): Boolean = historyStartDate() <= date.minusYears(1)

    /**
     * Réduit les deux historiques aux dates où ils ont tous les deux une clôture, pour les comparer
     * sur la même période et avec les mêmes dates. C'est l'**intersection** des deux ensembles de dates :
     * une date présente d'un seul côté (ETF pas encore créé, jour sans cotation) est écartée des deux côtés.
     * `null` s'ils n'ont aucune date en commun.
     */
    fun commonPeriodWith(other: ClosingPriceHistory): Pair<ClosingPriceHistory, ClosingPriceHistory>? {
        val commonDates = prices.map { it.date }.intersect(other.prices.map { it.date }.toSet())
        if (commonDates.isEmpty()) return null
        return restrictedTo(commonDates) to other.restrictedTo(commonDates)
    }

    /**
     * Rendement total sur tout l'historique : `dernière clôture / première clôture − 1`.
     * Exemple : de 100 à 125, le rendement total vaut 0,25, soit +25 %.
     */
    fun totalReturn(): BigDecimal = (growth() - BigDecimal.ONE).rounded()

    /**
     * Rendement annualisé : le rendement constant qu'il aurait fallu obtenir **chaque année** pour arriver
     * au même résultat. Il permet de comparer des périodes de durées différentes.
     *
     * Il est **composé** : les gains d'une année produisent eux-mêmes des gains l'année suivante. Un ETF
     * qui double en 5 ans n'a donc pas fait +20 % par an (100 % / 5), mais +14,87 %, car 1,1487⁵ ≈ 2.
     *
     * Formule, sur la durée réelle de l'historique : `(1 + rendement total)^(365,25 / nombre de jours) − 1`.
     * 365,25 est la durée moyenne d'une année, années bissextiles comprises.
     *
     * `null` si l'historique couvre moins d'un an : les normes GIPS interdisent d'annualiser une période
     * plus courte, car le chiffre serait trompeur (+5 % en un mois deviendrait environ +80 % « par an »).
     */
    fun annualizedReturn(): BigDecimal? = exactAnnualizedReturn()?.rounded()

    /**
     * Volatilité annualisée : l'ampleur habituelle des variations du cours sur un an.
     * Plus elle est élevée, plus le cours bouge fort, à la hausse comme à la baisse : c'est la mesure de risque.
     *
     * Calcul :
     * 1. les rendements journaliers (`+1 %`, `−0,5 %`…) ;
     * 2. leur **écart-type**, c'est-à-dire l'écart typique entre un rendement journalier et leur moyenne
     *    (racine carrée de la **variance**, la moyenne des écarts au carré). Comme on ne dispose que d'un
     *    échantillon de jours, la variance divise par `n − 1` et non par `n` (correction de Bessel) ;
     * 3. multiplié par `√252` pour passer d'une volatilité **par jour** à une volatilité **par an** :
     *    il y a environ 252 jours de bourse par an. Les variances de jours successifs s'additionnent, donc la variance
     *    annuelle vaut 252 fois la variance journalière, et l'écart-type (sa racine carrée) √252 fois l'écart-type journalier.
     *
     * Exemple : un écart-type journalier de 1 % donne une volatilité annuelle d'environ 15,9 % (1 % × √252).
     * `null` s'il y a moins de 2 rendements journaliers.
     */
    fun volatility(): BigDecimal? = exactVolatility()?.rounded()

    /**
     * Perte maximale (*max drawdown*) : la plus forte baisse entre un **sommet** (plus haut cours atteint
     * jusque-là) et un **creux** qui le suit : `creux / sommet − 1`. Elle montre ce qu'un investisseur
     * aurait perdu en achetant au pire moment et en revendant au pire moment suivant.
     *
     * On parcourt les cours dans l'ordre en retenant le sommet atteint jusqu'ici, et on mesure chaque jour
     * la baisse par rapport à ce sommet. Exemple : 100, 120, 90, 130 donne −25 % (de 120 à 90).
     * La valeur est négative, ou nulle si le cours n'a jamais baissé.
     */
    fun maxDrawdown(): Drawdown {
        var peak = prices.first()
        var worst = Drawdown(BigDecimal.ZERO, peak.date, peak.date)
        prices.forEach { price ->
            if (price.adjustedClose > peak.adjustedClose) peak = price
            val drawdown = price.adjustedClose.divide(peak.adjustedClose, MATH_CONTEXT) - BigDecimal.ONE
            if (drawdown < worst.value) worst = Drawdown(drawdown, peak.date, price.date)
        }
        return worst.copy(value = worst.value.rounded())
    }

    /**
     * Ratio rendement/risque : `rendement annualisé / volatilité annualisée`, soit le rendement obtenu
     * par unité de risque. Exemple : 10 % de rendement pour 15 % de volatilité donnent 0,67 ;
     * le même rendement pour 25 % de volatilité donne 0,40.
     *
     * C'est un **ratio de Sharpe** simplifié. Le vrai ratio de Sharpe retire d'abord du rendement le
     * **taux sans risque** (ce que rapporte un placement sûr, comme un emprunt d'État), que Twelve Data
     * ne fournit pas : il est donc pris égal à 0.
     *
     * Calculé sur les valeurs non arrondies, pour ne pas cumuler deux arrondis.
     * `null` si le rendement annualisé ou la volatilité est incalculable, ou si la volatilité est nulle
     * (division par zéro).
     */
    fun returnToRiskRatio(): BigDecimal? {
        val annualizedReturn = exactAnnualizedReturn() ?: return null
        val volatility = exactVolatility()?.takeIf { it.signum() != 0 } ?: return null
        return annualizedReturn.divide(volatility, MATH_CONTEXT).rounded()
    }

    fun performance(): Performance = Performance(
        totalReturn = totalReturn(),
        annualizedReturn = annualizedReturn(),
        volatility = volatility(),
        returnToRiskRatio = returnToRiskRatio(),
        maxDrawdown = maxDrawdown(),
    )

    /**
     * Courbe en **base 100** sur tout l'historique : chaque clôture est divisée par la première clôture
     * (la **base**), puis multipliée par 100 : `clôture / première clôture × 100`.
     * Les deux ETF d'une comparaison partent ainsi de 100, quel que soit le prix d'une part
     * (700 $ pour l'un, 50 $ pour l'autre), et une valeur de 150 se lit « +50 % depuis le départ ».
     *
     * Un point par jour de bourse : la courbe montre donc les mêmes sommets et creux que la perte maximale.
     */
    fun rebased(): List<RebasedPrice> {
        val base = prices.first().adjustedClose
        return prices.map {
            RebasedPrice(it.date, (it.adjustedClose.divide(base, MATH_CONTEXT) * BASE_100).roundedPrice())
        }
    }

    /**
     * Corrélation entre deux ETF : mesure s'ils montent et baissent **les mêmes jours**.
     * C'est un nombre entre −1 et 1 :
     * - proche de 1 : ils bougent presque toujours dans le même sens le même jour, et se protègent peu
     *   l'un l'autre en cas de baisse (peu de diversification) ;
     * - proche de 0 : leurs mouvements n'ont pas de lien ;
     * - négatif : quand l'un monte, l'autre a tendance à baisser.
     *
     * Calcul : coefficient de corrélation **de Pearson** entre les rendements journaliers des deux ETF :
     * `covariance(rA, rB) / (écart-type(rA) × écart-type(rB))`.
     * - Pour chaque jour, on mesure l'**écart** du rendement de chaque ETF à sa propre moyenne.
     * - La **covariance** additionne les produits de ces écarts jour par jour : positive si les deux ETF sont
     *   souvent au-dessus (ou au-dessous) de leur moyenne le même jour, négative s'ils s'opposent.
     * - Diviser par le produit des écarts-types ramène le résultat entre −1 et 1, quelle que soit la volatilité
     *   de chaque ETF. Les divisions par `n − 1` de la covariance et des variances s'annulent : elles sont omises.
     *
     * On utilise les rendements et non les prix : deux ETF qui montent tous les deux sur 5 ans auraient des prix
     * « corrélés » même s'ils ne bougent jamais le même jour.
     *
     * Les deux historiques doivent avoir les mêmes dates ([commonPeriodWith]).
     * `null` s'il y a moins de 2 rendements, ou si l'un des ETF ne varie jamais (écart-type nul, division par zéro).
     */
    fun correlationWith(other: ClosingPriceHistory): BigDecimal? {
        require(prices.map { it.date } == other.prices.map { it.date }) {
            "Both histories must have the same dates to be correlated"
        }
        val returns = dailyReturns()
        val otherReturns = other.dailyReturns()
        if (returns.size < 2) return null
        val mean = returns.average()
        val otherMean = otherReturns.average()
        val deviations = returns.map { it - mean }
        val otherDeviations = otherReturns.map { it - otherMean }
        val covariance = deviations.zip(otherDeviations).sumOf { (deviation, otherDeviation) -> deviation * otherDeviation }
        val variance = deviations.sumOf { it.pow(2, MATH_CONTEXT) }
        val otherVariance = otherDeviations.sumOf { it.pow(2, MATH_CONTEXT) }
        if (variance.signum() == 0 || otherVariance.signum() == 0) return null
        // √(varianceA × varianceB) = écart-type(A) × écart-type(B)
        return covariance.divide((variance * otherVariance).sqrt(MATH_CONTEXT), MATH_CONTEXT).rounded()
    }

    /** Croissance sur tout l'historique : `dernière clôture / première clôture` (1,20 = +20 %). */
    private fun growth(): BigDecimal = lastClose().adjustedClose.divide(prices.first().adjustedClose, MATH_CONTEXT)

    /** Rendement annualisé non arrondi (voir [annualizedReturn]). */
    private fun exactAnnualizedReturn(): BigDecimal? {
        if (!coversOneYearUntil(lastClose().date)) return null
        val days = ChronoUnit.DAYS.between(historyStartDate(), lastClose().date)
        return annualize(growth(), days / DAYS_PER_YEAR)
    }

    /** Volatilité annualisée non arrondie (voir [volatility]). */
    private fun exactVolatility(): BigDecimal? {
        val dailyReturns = dailyReturns()
        if (dailyReturns.size < 2) return null
        val mean = dailyReturns.average()
        // Variance d'échantillon : moyenne des écarts au carré, en divisant par n − 1
        val variance = dailyReturns
            .sumOf { (it - mean).pow(2, MATH_CONTEXT) }
            .divide(BigDecimal(dailyReturns.size - 1), MATH_CONTEXT)
        // Écart-type journalier (√variance), ramené à l'année (× √252)
        return variance.sqrt(MATH_CONTEXT) * TRADING_DAYS_PER_YEAR.sqrt(MATH_CONTEXT)
    }

    /**
     * Rendements journaliers simples, d'un jour de bourse au suivant : `cᵢ / cᵢ₋₁ − 1`.
     * Exemple : 100 puis 101 donne +0,01 (+1 %). Il y en a un de moins que de clôtures.
     */
    private fun dailyReturns(): List<BigDecimal> = prices.zipWithNext { previous, next ->
        next.adjustedClose.divide(previous.adjustedClose, MATH_CONTEXT) - BigDecimal.ONE
    }

    /**
     * Rendement annualisé composé : `croissance^(1 / années) − 1`, où le nombre d'années peut être décimal.
     * `BigDecimal` ne sait pas calculer une puissance non entière : le calcul passe par `Math.pow` sur des
     * `Double`, puis le résultat repasse en `BigDecimal` (exception à la règle « jamais de `Double` »).
     */
    private fun annualize(growth: BigDecimal, years: Double): BigDecimal =
        BigDecimal(growth.toDouble().pow(1.0 / years)) - BigDecimal.ONE

    private fun restrictedTo(dates: Set<LocalDate>): ClosingPriceHistory =
        ClosingPriceHistory(prices.filter { it.date in dates })

    /**
     * Clôture d'il y a N ans : la dernière clôture située au moins N ans avant la dernière clôture.
     * Si cette date tombe un jour de fermeture, c'est donc le jour de bourse précédent.
     */
    private fun referenceCloseOver(years: Long): ClosingPrice? {
        val referenceDate = lastClose().date.minusYears(years)
        return prices.lastOrNull { it.date <= referenceDate }
    }

    /** Historique réduit aux N dernières années, à partir de la clôture de référence. `null` s'il ne couvre pas N ans. */
    private fun windowOver(years: Long): ClosingPriceHistory? {
        val reference = referenceCloseOver(years) ?: return null
        return ClosingPriceHistory(prices.filter { it.date >= reference.date })
    }

    private fun List<BigDecimal>.average(): BigDecimal =
        fold(BigDecimal.ZERO, BigDecimal::add).divide(BigDecimal(size), MATH_CONTEXT)

    // HALF_EVEN : arrondi « au plus proche », et au chiffre pair en cas d'égalité (0,12345 → 0,1234 ; 0,12355 → 0,1236).
    // C'est l'arrondi bancaire : il évite de toujours arrondir les cas d'égalité vers le haut.
    private fun BigDecimal.rounded(): BigDecimal = setScale(RATE_SCALE, RoundingMode.HALF_EVEN)

    private fun BigDecimal.roundedPrice(): BigDecimal = setScale(PRICE_SCALE, RoundingMode.HALF_EVEN)

    companion object {
        val TTL: Duration = Duration.ofDays(1)

        // Précision des divisions et racines : 16 chiffres significatifs, comme un Double, mais en calcul décimal exact
        private val MATH_CONTEXT = MathContext.DECIMAL64
        // Nombre usuel de jours de bourse par an aux États-Unis (hors week-ends et jours fériés)
        private val TRADING_DAYS_PER_YEAR = BigDecimal(252)
        private val MIDDLE_POSITION = BigDecimal("0.5")
        private val BASE_100 = BigDecimal(100)
        // Durée moyenne d'une année en jours, années bissextiles comprises
        private const val DAYS_PER_YEAR = 365.25
        private const val RATE_SCALE = 4
        private const val PRICE_SCALE = 2

        fun fromUnsorted(prices: List<ClosingPrice>): ClosingPriceHistory =
            ClosingPriceHistory(prices.distinctBy { it.date }.sortedBy { it.date })

        fun isStale(fetchedAt: Instant?, now: Instant): Boolean =
            fetchedAt == null || fetchedAt.plus(TTL).isBefore(now)
    }
}

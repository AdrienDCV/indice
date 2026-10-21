# Plan d'implémentation : comparaison de deux ETF (`GET /etfs/compare`)

> Les conventions du projet sont définies dans le `CLAUDE.md`, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Il s'appuie sur la fiche détaillée (`plan-implementation-etf-detail.md`) : historique des clôtures stocké dans `etf_closing_price` et calculs dans `ClosingPriceHistory`.

## Avant de coder

1. **Lis le code existant** du domaine `etf` : `EtfDetailService`, `ClosingPriceHistory`, `EtfDetailMapper`, `ExceptionController`, et leurs tests.
2. **Présente ton plan** (fichiers créés, modifiés et déplacés) et attends la validation avant d'écrire du code.
3. **Économise le quota Twelve Data** : aucun appel réel dans les tests, et au plus 2 crédits pour la vérification manuelle (voir la section 11).

---

## 1. Objectif

Exposer `GET /etfs/compare?etfA=SPY&etfB=QQQ` (URL complète `/api/etfs/compare?...`), qui compare **deux ETF** du catalogue **sur une même période** :

- leurs indicateurs de performance et de risque, calculés sur la **période commune** ;
- leurs courbes de prix **ramenées à une base 100**, pour les superposer sur un graphique ;
- la **corrélation** entre les deux ETF, pour la leçon de diversification.

L'API **ne désigne aucun gagnant** : elle renvoie des valeurs brutes, et c'est l'utilisateur qui juge selon ses propres critères. Les symboles `<` et `>` et la mise en forme sont gérés par le mobile.

## 2. Hors périmètre

- La comparaison de plus de deux ETF.
- Le choix de la période par l'utilisateur (1 an, 3 ans, 5 ans) : la comparaison porte toujours sur toute la période commune. Piste retenue pour plus tard : un paramètre `period` qui recalcule **côté backend** la courbe (repartant de 100) et les indicateurs sur la fenêtre choisie, pour qu'ils restent cohérents. Un défilement horizontal de la courbe côté mobile a été écarté : la fenêtre affichée ne repartirait plus de 100, et les indicateurs porteraient sur une autre période que la courbe.
- Les simulations (« 1 000 $ investis il y a N ans », investissement mensuel, portefeuille fictif) : elles relèvent du futur module *Construire*.
- Les indicateurs déjà présents dans la fiche détail (rendements à 1 et 3 ans, fourchette sur 52 semaines) : le mobile renvoie vers la fiche.
- Tout système de préférences ou de recommandation : ce serait du conseil en investissement.
- Tout texte destiné à l'utilisateur : l'API ne renvoie que des données et des clés d'erreur.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Route | `GET /etfs/compare?etfA=SPY&etfB=QQQ`. Les paramètres reprennent le vocabulaire « ETF A / ETF B » du mobile |
| Nombre d'ETF | Exactement 2, deux paramètres obligatoires. Ce n'est pas un listing : pas de pagination |
| Période | **Période commune** : uniquement les dates où les deux ETF ont une clôture, sur 5 ans au plus. Tous les calculs utilisent cette période, dont les dates de début et de fin sont renvoyées |
| Données exploitables | Au moins **1 an** de période commune. Sinon erreur 422 qui désigne l'ETF en cause (A, B, ou les deux) |
| Indicateurs par ETF | Rendement total, rendement annualisé, volatilité annualisée, perte maximale, ratio rendement/risque |
| Indicateur de la paire | Corrélation des rendements journaliers |
| Courbes | Couvrent **toute la période commune**, avec **un point par jour de bourse**, en base 100 au premier jour de la période |
| Verdict | Aucun : pas de champ `winner`, `better`… |
| Fraîcheur | Même règle que la fiche détail : historique rechargé s'il a plus d'un jour (1 crédit par ETF, donc 2 au plus). Si Twelve Data est indisponible : données en base, `stale = true`. `stale` et `fetchedAt` sont renvoyés **pour chaque ETF** |
| Réutilisation | La logique de rafraîchissement est extraite de `EtfDetailService` dans un `ClosingPriceService` partagé (règle du Boy Scout) |
| Nombres | Taux en fractions à **4 décimales**, valeurs base 100 à **2 décimales** |

---

## 4. Choix des indicateurs

Cette section explique **pourquoi** chaque indicateur a été retenu et **comment** il est calculé. Elle sert aussi de référence pour les textes pédagogiques du mobile.

Chaque source a été consultée, et les citations reprennent le texte des pages. Son niveau de fiabilité est indiqué :
- **forte** : source primaire ou institutionnelle (auteur de la méthode, régulateur, institut de statistique, CFA Institute) ;
- **moyenne** : encyclopédie collaborative (Wikipédia), utile pour une définition standard mais sans autorité propre.

Aucune source institutionnelle en accès libre n'a pu être vérifiée pour la volatilité annualisée et la perte maximale : elles ne s'appuient que sur Wikipédia (les manuels de référence, comme celui de Hull, et l'article de Magdon-Ismail et Atiya sur la perte maximale ne sont pas consultables librement).

**Pourquoi ce niveau de confiance suffit pour Indice** :
- **Les formules sont standard.** Base 100, rendement total, rendement annualisé composé, volatilité (écart-type des rendements journaliers multiplié par `√252`), perte maximale, corrélation de Pearson et ratio de Sharpe sont des calculs de base de l'analyse financière, présents dans les programmes de formation (le CFA Institute en fait des objectifs d'apprentissage) et dans les outils grand public. Les sources consultées concordent, et aucune ne propose une formule différente. Une source de fiabilité moyenne suffit à documenter une définition aussi établie : elle ne sert pas à trancher un débat, seulement à rappeler une convention.
- **L'enjeu est limité.** Indice est un projet de cours, à visée pédagogique, qui ne donne aucun conseil en investissement et ne déclenche aucune transaction. Une imprécision n'aurait pas de conséquence financière pour l'utilisateur.
- **Les écarts au standard sont identifiés.** Ce qui relève d'un choix du projet, et non d'une formule standard, est listé à part (section 4.8) : ratio sans taux sans risque, durée en `jours / 365,25`, rendements simples plutôt que logarithmiques. Ce sont ces choix, et non les formules, qui méritent d'être discutés en revue.

Pour un usage réel (application publique, données servant à des décisions d'investissement), il faudrait s'appuyer sur un manuel de référence ou sur la méthodologie publiée d'un fournisseur d'indices, et faire valider les calculs par comparaison avec un outil reconnu.

### 4.1 Période commune

Deux chiffres ne se comparent honnêtement que s'ils portent sur la même période. Si l'ETF B n'existe que depuis 3 ans, comparer son rendement sur 3 ans au rendement sur 5 ans de l'ETF A n'a pas de sens.

- **Fin de la période** : la plus ancienne des deux dernières clôtures (en pratique, la même date pour deux ETF américains à jour).
- **Début de la période** : la plus récente des deux premières clôtures.
- **Dates retenues** : uniquement celles où **les deux** ETF ont une clôture (intersection). Les deux séries ont donc exactement les mêmes dates, ce qui est indispensable pour la corrélation.

### 4.2 Courbes en base 100

Les prix bruts ne se comparent pas : une part de SPY vaut environ 700 \$, une part d'un autre ETF peut valoir 50 $. On ramène donc chaque courbe à **100 le premier jour de la période commune** : `valeur = clôture / première clôture × 100`. Une valeur de 150 signifie « +50 % depuis le début de la période », quel que soit le prix de la part.

La courbe a **un point par jour de bourse** (environ 1 260 points par ETF sur 5 ans, soit environ 90 Ko de JSON pour la comparaison). Elle montre donc exactement les mêmes sommets et creux que la perte maximale, calculée elle aussi sur les clôtures quotidiennes. Si le poids de la réponse devenait gênant sur réseau mobile, la compression HTTP de Spring (`server.compression.enabled`) pourrait être activée sans changer l'API.

**Source** :
- **Forte** — [Indice — Insee](https://insee.fr/fr/metadonnees/definition/c1055) : *« L'indice d'une grandeur est le rapport entre la valeur de cette grandeur au cours d'une période courante et sa valeur au cours d'une période de base. »* et *« Souvent, on multiplie le rapport par 100 ; on dit : indice base 100 à telle période. »*

### 4.3 Indicateurs repris de la fiche détail

Les formules sont celles de la fiche détail (section 5.3 de son plan), appliquées à **toute la période commune** au lieu d'une fenêtre de N ans :

- **Rendement total** : `dernière clôture / première clôture − 1`.
- **Volatilité annualisée** : écart-type (échantillon, n − 1) des rendements journaliers, multiplié par `√252`.
- **Perte maximale** : plus forte baisse entre un sommet et le creux qui le suit, avec leurs dates.

**Sources** :
- **Moyenne** — [Volatility (finance) — Wikipédia (en)](https://en.wikipedia.org/wiki/Volatility_(finance)) : `σ annuelle = σ quotidienne × √P`, et *« A common assumption is that P = 252 trading days in any given year »*.
- **Moyenne** — [Bessel's correction — Wikipédia (en)](https://en.wikipedia.org/wiki/Bessel%27s_correction) : *« the use of n − 1 instead of n in the formula for the sample variance and sample standard deviation »*.
- **Moyenne** — [Drawdown (economics) — Wikipédia (en)](https://en.wikipedia.org/wiki/Drawdown_(economics)) : la perte maximale est *« the worst (the maximum) peak to valley loss »*. Ce passage porte la mention *« citation needed »* sur Wikipédia.

### 4.4 Rendement annualisé sur une durée quelconque

La période commune ne dure pas forcément un nombre entier d'années (par exemple 2,3 ans). On annualise donc avec la **durée réelle** :

```
rendement annualisé = (1 + rendement total)^(365,25 / nombre de jours) − 1
```

où `nombre de jours` est l'écart en jours calendaires entre la première et la dernière clôture de la période. Pour une période de 5 ans, on retrouve, à l'arrondi près, le résultat de la fiche détail.

Comme dans la fiche détail, la puissance non entière passe par `Math.pow` (exception documentée à la règle « jamais de `Double` »).

**Sources** :
- **Moyenne** — [Compound annual growth rate — Wikipédia (en)](https://en.wikipedia.org/wiki/Compound_annual_growth_rate) : `CAGR = (valeur finale / valeur initiale)^(1 / (t₁ − t₀)) − 1`, où `t₁ − t₀` est *« the number of years »*. La page ne traite pas explicitement d'une durée non entière : l'appliquer à une durée fractionnaire, exprimée en `nombre de jours / 365,25`, est une convention du projet (section 4.8).
- **Forte** — [GIPS Standards, Q&A — CFA Institute](https://www.gipsstandards.org/?GIPSID=370) : les normes internationales de présentation des performances indiquent que *« Returns for periods of less than one year must not be annualized. »* C'est ce qui justifie la règle « au moins 1 an de période commune ».

**Les normes GIPS** (*Global Investment Performance Standards*) sont publiées par le **CFA Institute**, l'organisme qui délivre le diplôme de référence des analystes financiers. Elles fixent la façon dont les gestionnaires de fonds présentent leurs performances à leurs clients, pour que les chiffres de deux gestionnaires soient comparables et honnêtes. Indice n'est pas soumis à ces normes, mais il en reprend cette règle de bon sens.

**Pourquoi ne pas annualiser une période courte** : le calcul extrapole la performance observée à une année entière, et gonfle les chiffres de façon trompeuse. Un ETF qui a gagné 5 % en un mois afficherait environ **+80 % « par an »** (`1,05¹² − 1`), alors que rien ne dit qu'il refera +5 % chaque mois. Dans le code, `annualizedReturn()` renvoie donc `null` sur moins d'un an, et la comparaison exige au moins un an de période commune.

### 4.5 Ratio rendement/risque

**Pourquoi** : un rendement seul ne dit rien du chemin parcouru. Deux ETF qui rapportent 10 % par an ne se valent pas si l'un y arrive sans à-coups et l'autre en alternant −30 % et +40 %. Le ratio répond à la question : **combien de rendement pour une unité de risque ?**

**Formule** :

```
ratio rendement/risque = rendement annualisé / volatilité annualisée
```

Exemple : 10 % de rendement pour 15 % de volatilité donnent un ratio de 0,67 ; 10 % pour 25 % de volatilité donnent 0,40.

**Limites, à rappeler dans la documentation** :
- C'est une **version simplifiée du ratio de Sharpe**. Le vrai Sharpe retire d'abord du rendement le **taux sans risque** (le rendement d'un placement sûr, comme un emprunt d'État à court terme). Twelve Data ne fournit pas ce taux : on ne l'appelle donc pas « Sharpe », pour ne pas employer le terme de façon inexacte. Identifiant : `returnToRiskRatio`.
- Le ratio ne dit pas quel ETF choisir : un investisseur qui supporte bien les variations peut préférer un ratio plus faible et un rendement plus élevé.
- Il vaut `null` si la volatilité est nulle (division impossible), un cas qui ne se produit pas avec de vraies données.

**Précision** : le ratio est calculé à partir du rendement annualisé et de la volatilité **non arrondis**, puis arrondi à 4 décimales. Le calculer à partir des valeurs déjà arrondies ajouterait une erreur d'arrondi.

**Sources** :
- **Forte** — [The Sharpe Ratio — William F. Sharpe (1994)](https://web.stanford.edu/~wfsharpe/art/sr/sr.htm), article de l'auteur du ratio : il définit le ratio comme le rendement différentiel attendu *« per unit of risk »* (section *The Ex Ante Sharpe Ratio*). Dans la section *Time Dependence*, il indique qu'il est *« common practice to "annualize" data »* avant de calculer le ratio, ce que nous faisons. Nuance : son annualisation additionne les rendements de chaque période (moyenne arithmétique), et il précise que tenir compte de la capitalisation rend la relation *« more complicated »*. Nous utilisons le rendement annualisé composé (section 4.4), par cohérence avec la fiche détail (section 4.8).
- **Moyenne** — [Ratio de Sharpe — Wikipédia](https://fr.wikipedia.org/wiki/Ratio_de_Sharpe) : formule `S = (R − r) / σ`, où `r` est *« le référentiel de comparaison choisi (en général le taux de placement sans risque) »*. Avec `r = 0`, on obtient notre ratio. La page est signalée par Wikipédia comme ne citant pas assez ses sources.

### 4.6 Corrélation

**Pourquoi** : c'est le seul indicateur qui porte sur la **paire** d'ETF, et c'est la leçon de **diversification**. Un débutant pense souvent qu'il est diversifié parce qu'il détient deux ETF. Mais si ces deux ETF montent et baissent les mêmes jours (deux ETF d'actions américaines, par exemple), ils chutent ensemble lors d'un krach : le second ne protège presque pas. Sans la composition des ETF (non fournie par l'offre gratuite de Twelve Data), la corrélation est le seul moyen de montrer que deux ETF « se ressemblent ».

**Lecture** : un nombre entre −1 et 1.
- Proche de **1** : les deux ETF bougent presque toujours dans le même sens, le même jour.
- Proche de **0** : leurs mouvements n'ont pas de lien.
- **Négatif** : quand l'un monte, l'autre a tendance à baisser.

**Formule** : coefficient de corrélation **de Pearson** entre les **rendements journaliers** des deux ETF, sur les dates de la période commune :

```
rᵢ = cᵢ / cᵢ₋₁ − 1                                  (rendement journalier, pour chaque ETF)
corrélation = covariance(rA, rB) / (écart-type(rA) × écart-type(rB))
```

avec la covariance et les écarts-types calculés sur l'échantillon (n − 1), comme la volatilité.

**Pourquoi les rendements journaliers et pas les prix** : deux ETF qui montent tous les deux sur 5 ans auraient des prix fortement « corrélés » même s'ils ne bougent jamais le même jour. Ce qui compte pour la diversification, c'est le comportement **au jour le jour**.

**Cas limite** : `null` si l'un des écarts-types est nul (prix constant). La règle « au moins 1 an de période commune » garantit assez de points.

**Sources** :
- **Forte** — [Portfolio Risk and Return: Part I — CFA Institute](https://www.cfainstitute.org/insights/professional-learning/refresher-readings/2026/portfolio-risk-return-part-1) (page publique du programme) : objectif *« calculate and interpret the mean, variance, and covariance (or correlation) of asset returns based on historical data »*, et conclusion *« Combining assets with low correlations reduces portfolio risk. »* La corrélation se calcule donc sur les **rendements**, et c'est elle qui mesure l'intérêt de la diversification.
- **Forte** — [Beginners' Guide to Asset Allocation, Diversification, and Rebalancing — SEC](https://www.sec.gov/investor/pubs/assetallocation.htm) (régulateur américain des marchés) : *« Historically, the returns of the three major asset categories have not moved up and down at the same time. »* C'est la leçon pédagogique visée.
- **Moyenne** — [Corrélation (statistiques) — Wikipédia](https://fr.wikipedia.org/wiki/Corr%C3%A9lation_(statistiques)) : coefficient de corrélation linéaire, *« quotient de leur covariance par le produit de leurs écarts types »*, *« compris dans [–1, 1] »*. La page rappelle aussi que deux variables « fortement corrélées » ne démontrent pas *« une relation de causalité »*.

L'explication « pourquoi pas les prix » ci-dessus est notre formulation : les sources calculent la corrélation sur les rendements, sans détailler le contre-exemple des prix. Certaines utilisent des rendements **logarithmiques** ; sur des variations journalières, l'écart avec les rendements simples est négligeable, et on garde les rendements simples, déjà utilisés pour la volatilité.

### 4.7 Documentation dans le code

Chaque **fonction qui réalise un calcul** (nouvelle ou créée par le refactoring) reçoit une courte KDoc : la formule, la raison du choix quand il n'est pas évident, et les cas où elle renvoie `null`. Les KDoc des fonctions existantes non modifiées seront ajoutées plus tard.

### 4.8 Choix propres au projet (sans source externe)

Ces choix sont des conventions décidées pendant le cadrage, pour la simplicité ou la pédagogie. Ils ne viennent pas d'une source :

| Choix | Raison |
|---|---|
| Période commune = intersection des dates | Comparer sur la même période et avoir les mêmes dates pour la corrélation |
| Au moins 1 an de période commune | Annualiser une période plus courte donnerait des chiffres trompeurs (règle alignée sur les normes GIPS, section 4.4) |
| Durée en années = `nombre de jours / 365,25` | Tient compte des années bissextiles ; redonne exactement 5 ans pour une période de 5 ans |
| Taux sans risque ignoré (ratio à `r = 0`) | Twelve Data ne fournit pas ce taux |
| Rendements simples plutôt que logarithmiques | Cohérence avec la volatilité déjà calculée dans la fiche détail |
| Ratio calculé avec le rendement annualisé composé, et non la moyenne arithmétique de Sharpe | Cohérence avec le rendement annualisé affiché, plus parlant pour un débutant |

---

## 5. Objets métier (`etf/models`)

### 5.1 `ClosingPriceHistory` (enrichi)

**Nouvelles méthodes**, qui travaillent sur **tout** l'historique :

| Méthode | Résultat |
|---|---|
| `commonPeriodWith(other): Pair<ClosingPriceHistory, ClosingPriceHistory>` | Les deux historiques réduits à leurs dates communes (section 4.1) |
| `coversOneYearUntil(date: LocalDate): Boolean` | Vrai si l'historique a une clôture à `date − 1 an` ou avant (même règle que la clôture de référence de la fiche détail) |
| `totalReturn(): BigDecimal` | Rendement total (section 4.3) |
| `annualizedReturn(): BigDecimal` | Rendement annualisé sur la durée réelle (section 4.4) |
| `volatility(): BigDecimal?` | Volatilité annualisée (`null` si moins de 2 rendements journaliers) |
| `maxDrawdown(): Drawdown` | Perte maximale |
| `performance(): Performance` | Regroupe les 5 indicateurs, dont le ratio rendement/risque (section 4.5) |
| `rebased(): List<RebasedPrice>` | Courbe en base 100 sur tout l'historique, un point par jour de bourse (section 4.2) |
| `correlationWith(other): BigDecimal?` | Corrélation des rendements journaliers (section 4.6). Exige les mêmes dates dans les deux historiques (`require`) |

**Refactoring (Boy Scout)** : les méthodes existantes ne dupliquent plus les calculs. `windowOver(years)` renvoie un `ClosingPriceHistory?` (au lieu d'une liste), et les méthodes `xxxOver(years)` délèguent aux nouvelles :

```kotlin
fun volatilityOver(years: Long): BigDecimal? = windowOver(years)?.volatility()
fun maxDrawdownOver(years: Long): Drawdown? = windowOver(years)?.maxDrawdown()
```

Le calcul des rendements journaliers, partagé par la volatilité et la corrélation, est extrait dans une fonction privée `dailyReturns()`. Les tests existants de `ClosingPriceHistoryTest` doivent passer **sans modification** : c'est la preuve que le refactoring ne change pas le comportement.

### 5.2 Objets de résultat

```kotlin
data class EtfPrices(
    val history: ClosingPriceHistory?,   // null si aucun cours n'a jamais été récupéré
    val fetchedAt: Instant?,
    val stale: Boolean,
)

data class Performance(
    val totalReturn: BigDecimal,
    val annualizedReturn: BigDecimal?,
    val volatility: BigDecimal?,
    val returnToRiskRatio: BigDecimal?,
    val maxDrawdown: Drawdown,
)

data class RebasedPrice(val date: LocalDate, val value: BigDecimal)

data class DateRange(val startDate: LocalDate, val endDate: LocalDate)   // invariant : startDate <= endDate
```

`EtfPrices` regroupe les cours d'un ETF et leur fraîcheur. Le nom `RetrievedClosingPriceHistory`, d'abord prévu sur le modèle de `RetrievedEtfCatalog`, a été écarté car il décrivait comment l'objet est obtenu plutôt que ce qu'il contient (voir section 13).

### 5.3 `ComparedEtf` et `EtfComparison`

```kotlin
data class ComparedEtf(
    val etf: Etf,
    val performance: Performance,
    val rebasedPrices: List<RebasedPrice>,
    val fetchedAt: Instant?,
    val stale: Boolean,
)

data class EtfComparison(
    val etfA: ComparedEtf,
    val etfB: ComparedEtf,
    val commonPeriod: DateRange,
    val correlation: BigDecimal?,
)
```

**Fabrique** `EtfComparison.between(etfA: Etf, etfAPrices: EtfPrices, etfB: Etf, etfBPrices: EtfPrices): EtfComparison`, dans le `companion object`. C'est elle qui porte **toutes** les règles de la comparaison :

1. **Vérifier les données**. La fin de la période commune est la plus ancienne des deux dernières clôtures. Un ETF manque de données si son historique est `null`, ou s'il ne couvre pas 1 an avant cette date (`coversOneYearUntil`). Selon le cas, lever `InsufficientComparisonDataException` avec la clé de l'ETF A, de l'ETF B ou des deux (section 7).
2. **Réduire** les deux historiques à la période commune (`commonPeriodWith`).
3. **Construire** chaque `ComparedEtf` : `performance()`, `rebased()`, `fetchedAt` et `stale`.
4. **Calculer** la corrélation (`correlationWith`) et la période commune (`DateRange` de la première à la dernière date commune).

Comme les deux ETF couvrent chacun 1 an avant la fin de la période commune, la période commune dure elle aussi au moins 1 an : aucun indicateur n'est incalculable, sauf en cas de variance nulle.

La constante `MINIMUM_COMMON_PERIOD_YEARS = 1L` reste dans `EtfComparison` : c'est une règle métier stable, pas un paramétrage (même logique que `TTL`).

---

## 6. Services

### 6.1 Nouveau `ClosingPriceService.retrievePrices(etf: Etf): EtfPrices`

Logique **déplacée** depuis `EtfDetailService`, sans changement de comportement (`@Transactional`) :

1. `fetchedAt` = date de récupération des cours en base.
2. Si l'historique n'est pas périmé : charger les cours en base et renvoyer `stale = false`.
3. Sinon, appeler `TwelveDataClient.fetchDailyClosingPrices` :
   - **succès** : remplacer les cours en base et construire l'historique à partir des cours reçus, sans relire la base. `stale = false`, `fetchedAt = now` ;
   - **`TwelveDataUnavailableException`** : journaliser un `warn`, charger les cours en base et renvoyer `stale = true` (historique `null` si aucun cours en base).

Dépendances : `EtfClosingPriceRepository`, `TwelveDataClient`, `Clock`. Les constantes `HISTORY_YEARS` et `HISTORY_MARGIN_DAYS` déménagent avec la logique.

### 6.2 `EtfDetailService` (simplifié)

```kotlin
@Transactional
fun retrieveEtf(ticker: String): EtfDetail {
    val etf = findEtf(Etf.normalizeTicker(ticker))
    val retrieved = closingPriceService.retrievePrices(etf)
    return EtfDetail(etf, retrieved.history?.marketData(), retrieved.fetchedAt, retrieved.stale)
}
```

Il ne dépend plus que de `EtfRepository` et `ClosingPriceService`. Le comportement de `GET /etfs/{ticker}` ne change pas.

### 6.3 Nouveau `EtfComparisonService.compare(tickerA: String, tickerB: String): EtfComparison`

`@Transactional` (le rafraîchissement peut écrire en base) :

1. Normaliser les deux tickers (`Etf.normalizeTicker`, 400 si invalide).
2. S'ils sont identiques : `SameEtfComparisonException`, **avant** tout appel à Twelve Data.
3. Charger les deux ETF (`EtfNotFoundException` si l'un est inconnu).
4. `retrievePrices` pour chacun.
5. Renvoyer `EtfComparison.between(...)`. Le service ne fait aucun calcul ni aucun contrôle sur les données.

La recherche d'un ETF par ticker (`findEtf`) existe alors dans `EtfDetailService` et `EtfComparisonService`. Ce sont deux occurrences : on ne factorise pas (règle « DRY à partir de la 3e duplication »).

---

## 7. Erreurs

| Cas | Statut | Clé | Origine |
|---|---|---|---|
| Paramètre `etfA` ou `etfB` absent | 400 | `error.request.missing-parameter` | Nouveau handler `MissingServletRequestParameterException` dans `ExceptionController` |
| Ticker mal formé | 400 | `error.etfs.invalid-ticker` | `InvalidTickerException` (existe) |
| Ticker inconnu | 404 | `error.etfs.etf-not-found` | `EtfNotFoundException` (existe) |
| Deux fois le même ETF (`SPY` et ` spy `) | 400 | `error.etfs.same-etf-comparison` | Nouvelle `SameEtfComparisonException` |
| ETF A sans données exploitables | 422 | `error.etfs.etf-a-insufficient-data` | Nouvelle `InsufficientComparisonDataException` |
| ETF B sans données exploitables | 422 | `error.etfs.etf-b-insufficient-data` | Idem |
| Les deux ETF sans données exploitables | 422 | `error.etfs.etfs-insufficient-data` | Idem |

- La réponse d'erreur reste une liste avec **une seule entrée**, comme aujourd'hui. `BusinessException` n'est pas modifiée.
- `InsufficientComparisonDataException` reçoit sa clé en paramètre, et expose les trois clés en constantes dans son `companion object`. Statut : `HttpStatus.UNPROCESSABLE_CONTENT` (`UNPROCESSABLE_ENTITY` est déprécié dans Spring 7).
- Le handler du paramètre manquant est dans `common/` : sa clé est donc générique (`error.request.…`), sans référence au domaine `etfs`.
- Sans ce handler, un paramètre manquant renverrait aujourd'hui une **500** (`error.unexpected`).

---

## 8. Endpoint

### 8.1 Controller

Nouveau `EtfComparisonController` (`etf/controllers/`), comme prévu par l'exemple du `CLAUDE.md` :

```kotlin
@GetMapping("/etfs/compare")
fun compareEtfs(@RequestParam etfA: String, @RequestParam etfB: String): EtfComparisonResponseDto =
    etfComparisonService.compare(etfA, etfB).toDto()
```

`/etfs/compare` n'entre pas en conflit avec `/etfs/{ticker}` : Spring privilégie le chemin littéral.

### 8.2 Réponse

```json
{
  "commonPeriod": { "startDate": "2021-10-20", "endDate": "2026-10-19" },
  "correlation": 0.9312,
  "etfA": {
    "ticker": "SPY",
    "exchange": "NYSE",
    "name": "State Street SPDR S&P 500 ETF Trust",
    "currency": "USD",
    "fetchedAt": "2026-10-20T08:00:00Z",
    "stale": false,
    "performance": {
      "totalReturn": 0.8123,
      "annualizedReturn": 0.1263,
      "volatility": 0.1712,
      "returnToRiskRatio": 0.7377,
      "maxDrawdown": { "value": -0.2450, "peakDate": "2022-01-03", "troughDate": "2022-10-12" }
    },
    "rebasedPrices": [
      { "date": "2021-10-20", "value": 100.00 },
      { "date": "2021-10-21", "value": 100.87 }
    ]
  },
  "etfB": { "…": "même structure que etfA" }
}
```

### 8.3 DTOs et mapper

- `dtos/responses/` : `EtfComparisonResponseDto`, `ComparedEtfResponseDto`, `PerformanceResponseDto`, `RebasedPriceResponseDto`, `DateRangeResponseDto`. On réutilise `MaxDrawdownResponseDto`.
- `mappers/EtfComparisonMapper.kt` : `EtfComparison.toDto()` et les sous-objets. `Drawdown.toDto()` existe déjà dans `EtfDetailMapper.kt`.

---

## 9. Contrat d'API pour le mobile

**Nouvel endpoint, aucun changement cassant** : `GET /etfs/{ticker}` garde exactement la même réponse.

Pour l'équipe Flutter (propositions, à ajuster) :

| Situation | Signal | Affichage proposé |
|---|---|---|
| Comparaison | Réponse 200 | Les deux courbes base 100 superposées, puis un tableau des indicateurs côte à côte. Les `<` et `>` restent factuels (« plus volatil »), jamais « meilleur » |
| Données anciennes pour un ETF | `stale = true` sur cet ETF | Bandeau *« Données de l'ETF A au 19/10/2026, mise à jour impossible »* |
| Données insuffisantes | 422 et l'une des trois clés | *« Comparaison impossible : données insuffisantes pour l'ETF A »* (ou B, ou les deux) |
| Même ETF des deux côtés | 400 `error.etfs.same-etf-comparison` | Idéalement évité en amont, en désactivant l'ETF déjà choisi dans le sélecteur |

Textes pédagogiques à prévoir : la période commune (« comparaison du 20/10/2021 au 19/10/2026 »), la lecture de la base 100, du ratio et de la corrélation (section 4), et le rappel que les performances passées ne préjugent pas des performances futures.

### 9.1 Bulles d'information (à faire côté mobile)

Idée retenue pendant le cadrage : chaque indicateur est accompagné d'une **petite bulle d'information** (icône « i » qui ouvre un *tooltip*), qui explique à quoi il sert. Les textes relèvent du mobile : l'API ne renvoie aucun texte. Les mêmes bulles peuvent servir dans la fiche détail.

Textes proposés (à ajuster), courts, neutres et sans jugement :

| Indicateur | Texte de la bulle |
|---|---|
| Courbe en base 100 | Les deux ETF partent de 100 au début de la période. Une valeur de 150 signifie +50 % depuis le départ, quel que soit le prix d'une part. |
| Période commune | Les indicateurs sont calculés sur les dates où les deux ETF ont un cours, pour les comparer sur la même période. |
| Rendement total | Gain ou perte sur toute la période, dividendes réinvestis. |
| Rendement annualisé | Rendement moyen par an sur la période. Il permet de comparer des durées différentes. |
| Volatilité | Ampleur habituelle des variations du prix sur un an. Plus elle est élevée, plus le prix bouge fort, à la hausse comme à la baisse. |
| Perte maximale | Plus forte baisse entre un sommet et le creux qui a suivi. Elle montre ce qu'un investisseur aurait pu perdre au pire moment. |
| Ratio rendement/risque | Rendement obtenu pour une unité de volatilité. Il ne dit pas quel ETF choisir : chacun juge selon sa tolérance aux variations. |
| Corrélation | Entre −1 et 1. Proche de 1 : les deux ETF montent et baissent souvent les mêmes jours, et se protègent peu l'un l'autre. Proche de 0 : leurs mouvements sont peu liés. |

Chaque bulle peut finir par le rappel : *« Les performances passées ne préjugent pas des performances futures. »*

---

## 10. Tests

Aucun appel réel. Conventions du `CLAUDE.md`.

| Classe | Contenu |
|---|---|
| **`ClosingPriceHistoryTest`** (prioritaire) | Tests existants inchangés et verts. Nouveaux tests sur des séries construites à la main : `commonPeriodWith` (dates décalées, dates manquantes d'un côté) ; `coversOneYearUntil` (exactement 1 an, un jour de moins, jour de fermeture) ; `totalReturn` ; `annualizedReturn` (période de 5 ans identique à la fiche détail, période non entière) ; `performance` et ratio (cas nominal, volatilité nulle) ; `rebased` (premier point à 100, un point par clôture, creux de la perte maximale visible); `correlationWith` (séries identiques → 1, séries opposées → −1, variance nulle → `null`, dates différentes → exception) |
| **`EtfComparisonTest`** | Cas nominal ; A sans historique ; B couvrant moins d'un an ; les deux en défaut (clé `etfs`) ; aucune date commune (clé `etfs`) ; année mesurée jusqu'à la plus ancienne des deux dernières clôtures ; `stale` et `fetchedAt` reportés sur le bon ETF ; période commune quand les historiques commencent à des dates différentes ; corrélation |
| `DateRangeTest` | Invariant `startDate <= endDate` |
| `ClosingPriceServiceTest` (MockK) | Tests de rafraîchissement **déplacés** depuis `EtfDetailServiceTest` : cours à jour, cours périmés, échec de l'API avec et sans cours en base |
| `EtfDetailServiceTest` (MockK) | Réduit : ETF inconnu, assemblage de `EtfDetail` à partir de `EtfPrices` (avec et sans historique) |
| `EtfComparisonServiceTest` (MockK) | Tickers identiques après normalisation : exception et **aucun** appel à `ClosingPriceService` ; ETF inconnu ; cas nominal |
| `EtfComparisonMapperTest` | Conversion complète, avec ratio et corrélation `null` |
| `EtfComparisonControllerTest` (`@WebMvcTest`) | 200 avec le JSON attendu ; paramètre manquant → 400 ; ticker invalide → 400 ; inconnu → 404 ; même ETF → 400 ; données insuffisantes → 422 |
| `ExceptionControllerTest` | Nouveau handler `MissingServletRequestParameterException` |

---

## 11. Vérification manuelle

Au plus **2 crédits** Twelve Data :

1. `curl "http://localhost:8080/api/etfs/compare?etfA=spy&etfB=qqq"` renvoie la comparaison. Coût : 0 à 2 crédits, selon que les historiques ont déjà été rafraîchis aujourd'hui par la fiche détail.
2. Le même appel une seconde fois ne déclenche aucun appel à Twelve Data.
3. Sans crédit : `?etfA=SPY&etfB=spy` → 400, `?etfA=SPY` → 400, `?etfA=SPY&etfB=ARKK` → 404.

Avant de lancer l'application, vérifier que le port 8080 est libre (l'application peut déjà tourner depuis IntelliJ).

---

## 12. Documentation

- **Glossaire**, section Finance : période commune, base 100, ratio rendement/risque (et sa différence avec le ratio de Sharpe), ratio de Sharpe, taux sans risque, corrélation. Compléter « Diversification » avec le lien vers la corrélation, et « Historique des clôtures » pour mentionner la comparaison.
- **Glossaire**, section Application : comparaison d'ETF (`EtfComparison`), ETF A / ETF B.
- **`CLAUDE.md`** : remplacer l'exemple de route `/etfs/compare?tickers=...` par `/etfs/compare?etfA=...&etfB=...`.
- **KDoc** sur les fonctions de calcul (section 4.7), rédigées pour un lecteur qui ne connaît pas la finance : vocabulaire, formule, exemple chiffré et cas où la fonction renvoie `null`.
- **Glossaire** : normes GIPS (règle « pas d'annualisation sur moins d'un an », section 4.4).

## 13. Ajustements pendant le développement

Écarts entre ce plan et le code livré :

| Sujet | Plan | Code livré | Raison |
|---|---|---|---|
| `annualizedReturn()` | Renvoie toujours une valeur | Renvoie `null` si l'historique couvre moins d'un an ; `Performance.annualizedReturn` et le champ JSON sont donc nullables | Règle GIPS portée par l'objet lui-même. En pratique, la règle « 1 an minimum » de la comparaison rend ce cas quasi impossible (seulement si les dates communes sont décalées de quelques jours) |
| `annualizedReturnOver(years)` (fiche détail) | Délègue au nouveau calcul | Garde son exposant en années entières (`1/N`), avec un calcul partagé (`annualize`) | Le passage à `jours / 365,25` aurait légèrement changé les valeurs de la fiche détail, qui devait rester identique |
| Nom de l'objet « cours + fraîcheur » | `RetrievedClosingPriceHistory`, `retrieveHistory` | `EtfPrices`, `ClosingPriceService.retrievePrices`, paramètres `etfAPrices` / `etfBPrices` | Nommer l'objet par son contenu plutôt que par sa provenance. `RetrievedEtfCatalog` garde son nom : incohérence à traiter plus tard |
| Courbe en base 100 | Un point par semaine (`weeklyRebased`) | Un point par jour de bourse (`rebased`) | Avec un point par semaine, le creux de la perte maximale pouvait manquer sur la courbe. Le quotidien supprime cet écart et simplifie le code, pour une réponse d'environ 90 Ko |
| Ratio rendement/risque | Dans `ClosingPriceHistory` | Méthode publique `returnToRiskRatio()`, appelée par `performance()` | Testable seule, sur les valeurs non arrondies |
| Aucune date commune | Non prévu | 422 avec la clé des deux ETF (`error.etfs.etfs-insufficient-data`) | Cas théorique (historiques qui se chevauchent sans date commune) qui aurait sinon provoqué une erreur 500 |
| Période d'un an | Mesurée jusqu'à la fin de la période commune | Idem, chaque ETF étant contrôlé séparément ; la période commune réelle peut donc être plus courte de quelques jours si les dates ne coïncident pas | Garder une seule règle simple, sans second contrôle |

## 14. Critères de fin

- [x] `./mvnw clean test` passe (125 tests ; base Docker démarrée, profil `test` depuis la PR #9).
- [x] Les tests existants de `ClosingPriceHistoryTest` passent sans modification.
- [ ] `GET /api/etfs/SPY` renvoie exactement la même réponse qu'avant le refactoring.
- [ ] `GET /api/etfs/compare?etfA=SPY&etfB=QQQ` renvoie la comparaison, et les cas d'erreur de la section 7 renvoient le bon statut et la bonne clé.
- [x] Aucune règle de calcul ni de contrôle des données dans les services ou le controller : tout est dans `ClosingPriceHistory` et `EtfComparison` (seule exception : le contrôle « même ETF des deux côtés », fait dans le service avant tout appel à Twelve Data).
- [x] Aucun champ de « verdict » dans la réponse.
- [x] Chaque fonction de calcul nouvelle ou modifiée a sa KDoc.
- [ ] Quota consommé pendant le développement : 2 crédits au plus.

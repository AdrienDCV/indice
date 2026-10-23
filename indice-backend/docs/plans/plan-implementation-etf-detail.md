# Plan d'implémentation : détail d'un ETF (`GET /etfs/{ticker}`)

> Les conventions du projet sont définies dans le `CLAUDE.md`, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Il s'appuie sur le catalogue migré vers Twelve Data (`plan-implementation-catalogue-twelve-data.md`).

## Avant de coder

1. **Lis le code existant** du domaine `etf` : catalogue, `TwelveDataClient`, `EtfService`, `ExceptionController`.
2. **Présente ton plan** (fichiers créés et modifiés, dépendances) et attends la validation avant d'écrire du code.
3. **Économise le quota Twelve Data** : aucun appel réel dans les tests, et deux appels manuels au total (voir la section 11).

---

## 1. Objectif

Exposer `GET /etfs/{ticker}` (URL complète `/api/etfs/{ticker}`), qui renvoie la **fiche détaillée** d'un ETF du catalogue : son identité et des **indicateurs de performance et de risque** calculés à partir de **5 ans de cours de clôture quotidiens**.

La fiche s'adresse à des débutants et sert de base à la future comparaison d'ETF.

## 2. Hors périmètre

- Les fondamentaux (frais, encours, composition) : aucune source gratuite ne les fournit (voir le plan du catalogue Twelve Data).
- La série de cours pour un graphique, la comparaison de plusieurs ETF et les simulations. L'historique stocké par ce plan leur servira plus tard. La série de cours a depuis été ajoutée pour l'écran mobile du détail (section 14).
- Toute tâche planifiée.
- Tout texte destiné à l'utilisateur : l'API ne renvoie que des données (les textes relèvent du mobile).

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Route | `GET /etfs/{ticker}`. Le ticker est mis en majuscules ; un ticker invalide renvoie 400 |
| Périmètre | Uniquement les ETF du catalogue ; sinon 404 (`EtfNotFoundException`) |
| Source | `time_series` de Twelve Data : quotidien, 5 ans, `adjust=all` (dividendes réinvestis), 1 crédit par appel |
| Stockage | Les **cours de clôture bruts**, dans `etf_closing_price` (environ 1 260 lignes par ETF) |
| Calcul | **À la volée**, à chaque requête, par l'objet métier `ClosingPriceHistory` |
| Fraîcheur | Cours valables **1 jour**. Appel à Twelve Data seulement si les cours sont absents ou périmés |
| Échec de l'API | 200 avec les derniers cours connus et `stale = true` ; `marketData = null` si aucun cours n'a jamais été récupéré |
| Indicateur incalculable | `null` (historique trop court) |
| Retrait d'un ETF du catalogue | Ses cours sont supprimés avec lui (`ON DELETE CASCADE`) |
| Nombres | `BigDecimal`, taux en **fractions** (`0.142` pour 14,2 %) |

---

## 4. API externe : `time_series` de Twelve Data

```
GET https://api.twelvedata.com/time_series?symbol=SPY&interval=1day&start_date=2021-10-13&adjust=all&order=asc&outputsize=5000
```

- **1 crédit** par appel. Clé dans l'en-tête `Authorization: apikey <clé>`, déjà configurée dans `TwelveDataClient`.
- `start_date` = date du jour moins 5 ans moins 7 jours, pour avoir un cours de clôture à 5 ans même si cette date tombe un jour de fermeture.
- `adjust=all` : cours ajustés des divisions d'actions **et des dividendes**. Les rendements sont donc des rendements **totaux**.
- **À vérifier en premier** (1 appel manuel) : que l'offre gratuite accepte `adjust=all`. Sinon, utiliser la valeur par défaut `splits` (dividendes non inclus) et le signaler dans la section 12 et dans la PR.

**Format de la réponse :**

```json
{
  "meta": { "symbol": "SPY", "interval": "1day", "currency": "USD", "exchange": "NYSE", "type": "ETF" },
  "values": [
    { "datetime": "2021-10-13", "open": "…", "high": "…", "low": "…", "close": "434.18", "volume": "…" }
  ],
  "status": "ok"
}
```

- Les valeurs sont des **chaînes** : Jackson les convertit en `BigDecimal` et `LocalDate`.
- Seuls `datetime` et `close` sont utilisés.
- Les erreurs suivent le même format que pour le catalogue (`"status": "error"` avec un HTTP 200, ou statut HTTP en erreur).

---

## 5. Objets métier (`etf/models`)

### 5.1 `ClosingPrice`

```kotlin
data class ClosingPrice(val date: LocalDate, val adjustedClose: BigDecimal)
```

- Invariant : `adjustedClose > 0`.

### 5.2 `ClosingPriceHistory`

Historique des clôtures d'**un** ETF, trié par date croissante. C'est le cœur de la fonctionnalité : **toute la logique de calcul est ici**, testée sans mock.

```kotlin
data class ClosingPriceHistory(val prices: List<ClosingPrice>)
```

- Invariants : liste non vide, dates strictement croissantes, sans doublon. Le mapper trie avant de construire l'objet.

| Méthode | Résultat |
|---|---|
| `lastClose(): ClosingPrice` | La dernière clôture |
| `historyStartDate(): LocalDate` | La date de la première clôture |
| `returnOver(years: Long): BigDecimal?` | Rendement sur N ans |
| `annualizedReturnOver(years: Long): BigDecimal?` | Rendement annualisé sur N ans |
| `volatilityOver(years: Long): BigDecimal?` | Volatilité annualisée sur N ans |
| `maxDrawdownOver(years: Long): Drawdown?` | Perte maximale sur N ans |
| `fiftyTwoWeekRange(): PriceRange?` | Fourchette sur 52 semaines |
| `marketData(): MarketData` | Regroupe tous les indicateurs de la fiche |

Constante : `TTL = Duration.ofDays(1)`, et fonction `isStale(fetchedAt: Instant?, now: Instant)` dans le `companion object`, sur le modèle de `EtfCatalog.isStale`.

### 5.3 Conventions de calcul

Toutes les fenêtres partent de la **date de la dernière clôture** (et non de la date du jour), pour que les indicateurs restent cohérents le week-end.

- **Clôture de référence à N ans** : la dernière clôture dont la date est **inférieure ou égale** à (date de la dernière clôture − N ans). S'il n'y en a pas, l'historique est trop court et l'indicateur vaut `null`.
- **Rendement sur N ans** : `dernière clôture / clôture de référence − 1`.
- **Rendement annualisé sur N ans** : `(1 + rendement sur N ans)^(1/N) − 1`.
- **Volatilité sur 1 an** : écart-type (échantillon, n − 1) des rendements journaliers simples (`cᵢ / cᵢ₋₁ − 1`) des clôtures postérieures à la clôture de référence à 1 an, multiplié par `√252`.
- **Perte maximale sur 5 ans** : sur les clôtures de la fenêtre, la plus forte baisse `creux / sommet précédent − 1` (valeur négative ou nulle), avec la date du sommet et celle du creux. Elle vaut 0 si les cours n'ont jamais baissé. Si l'historique ne couvre pas 5 ans, elle vaut `null`.
- **Fourchette sur 52 semaines** : plus bas et plus haut des clôtures de la dernière année (fenêtre de la clôture de référence à 1 an incluse), et `position = (dernière clôture − bas) / (haut − bas)`, entre 0 et 1. Si `haut = bas`, `position = 0.5`.

**Précision** : les calculs se font en `BigDecimal` avec `MathContext.DECIMAL64`, et seuls les résultats exposés sont arrondis (`HALF_EVEN`), pour l'affichage : **4 décimales pour les taux** (2 décimales en pourcentage, ex. `0.1661` = 16,61 %) et **2 décimales pour les prix** (`lastClose`, bornes de la fourchette). Les cours stockés et les calculs intermédiaires gardent toute leur précision. Seule la puissance non entière du rendement annualisé passe par un `Double` (`Math.pow`), le `BigDecimal` n'ayant pas d'opération équivalente. C'est une **exception documentée** à la règle « jamais de `Double` » du `CLAUDE.md`, limitée à cet endroit.

### 5.4 Objets de résultat

```kotlin
data class Drawdown(val value: BigDecimal, val peakDate: LocalDate, val troughDate: LocalDate)
data class PriceRange(val low: BigDecimal, val high: BigDecimal, val position: BigDecimal)

data class MarketData(
    val lastClose: ClosingPrice,
    val historyStartDate: LocalDate,
    val returnOneYear: BigDecimal?,
    val returnThreeYears: BigDecimal?,
    val returnFiveYears: BigDecimal?,
    val annualizedReturnFiveYears: BigDecimal?,
    val volatilityOneYear: BigDecimal?,
    val maxDrawdownFiveYears: Drawdown?,
    val fiftyTwoWeekRange: PriceRange?,
)

data class EtfDetail(
    val etf: Etf,
    val marketData: MarketData?,
    val closingPricesFetchedAt: Instant?,
    val stale: Boolean,
)
```

---

## 6. Persistance

### 6.1 Migration `V3__create_etf_closing_price_table.sql`

```sql
CREATE TABLE IF NOT EXISTS etf_closing_price (
    id             UUID           PRIMARY KEY,
    etf_id         UUID           NOT NULL REFERENCES etf (id) ON DELETE CASCADE,
    trading_date   DATE           NOT NULL,
    adjusted_close NUMERIC(19, 6) NOT NULL,
    fetched_at     TIMESTAMPTZ    NOT NULL,
    CONSTRAINT etf_closing_price_etf_date_key UNIQUE (etf_id, trading_date)
);
```

- La contrainte d'unicité `(etf_id, trading_date)` crée aussi l'index utilisé par les lectures par ETF.
- `ON DELETE CASCADE` : la synchronisation du catalogue supprime les ETF retirés avec `deleteAllByIdInBatch`, une suppression SQL directe que la cascade de la base suit bien.
- **`fetched_at` est stocké sur chaque ligne** : tous les cours d'un ETF sont remplacés ensemble, donc ils partagent la même valeur. Ce choix évite de toucher à la table `etf`, que la synchronisation du catalogue réécrit entièrement : une colonne « date de récupération des cours » sur `etf` serait remise à `null` à chaque synchronisation.

### 6.2 Entité et repository

- `EtfClosingPriceEntity` (`@Table(name = "etf_closing_price")`) : `id`, `etfId`, `tradingDate`, `adjustedClose`, `fetchedAt`. L'`id` n'a pas de sens métier (`ClosingPrice` n'en a pas) : il est **généré par Hibernate** (`@GeneratedValue(strategy = GenerationType.UUID)`, côté application, sans aller-retour avec la base). Elle référence l'ETF par son identifiant (`etfId: UUID`), sans relation JPA : c'est suffisant et ça évite les chargements implicites.
- **Insertion en lot efficace** : l'`id` étant `null` à la création, Spring Data fait directement un `persist`, sans `SELECT` préalable (ce qui aurait été le cas avec un identifiant fourni par le code). Le lot JDBC est activé dans `application.yaml` :

  ```yaml
  spring:
    jpa:
      properties:
        hibernate:
          jdbc.batch_size: 100
          order_inserts: true
  ```
- `EtfClosingPriceRepository` :
  - `findAllByEtfIdOrderByTradingDateAsc(etfId)` ;
  - `findFirstByEtfIdOrderByFetchedAtDesc(etfId)`, pour la date de récupération ;
  - `deleteAllByEtfId(etfId)` en **requête JPQL explicite** (`@Modifying @Query("delete from EtfClosingPriceEntity c where c.etfId = :etfId")`), pour supprimer en une seule requête SQL et non ligne par ligne.
- `EtfRepository` : ajouter `findByTicker(ticker): EtfEntity?`.

---

## 7. Client, DTOs et mappers

### 7.1 `TwelveDataClient`

Ajouter `fun fetchDailyClosingPrices(ticker: String, startDate: LocalDate): List<TwelveDataPriceDto>`, avec les mêmes règles d'erreur que `fetchEtfs` (`TwelveDataUnavailableException` si erreur réseau, statut HTTP en erreur, `"status": "error"`, JSON invalide ou `values` vide). Journaliser un `info` avec le ticker, sans la clé.

### 7.2 DTOs

- **Entrants** (`dtos/twelvedata`) :
  ```kotlin
  data class TwelveDataTimeSeriesDto(val values: List<TwelveDataPriceDto>?, val status: String?)
  data class TwelveDataPriceDto(val datetime: LocalDate, val close: BigDecimal)
  ```
- **Sortants** (`dtos/responses`) : `EtfDetailResponseDto`, `MarketDataResponseDto`, `ReturnsResponseDto`, `MaxDrawdownResponseDto`, `PriceRangeResponseDto`, selon la forme de la section 8.

### 7.3 Mappers

- `TwelveDataPriceDto.toModel(): ClosingPrice`.
- `EtfClosingPriceEntity.toModel()` et `ClosingPrice.toEntity(etfId, fetchedAt)`.
- `EtfDetail.toDto(): EtfDetailResponseDto`, et les sous-objets.
- La construction de `ClosingPriceHistory` trie les cours par date (`sortedBy`) : la liste reçue de Twelve Data ou de la base n'a pas à être triée.

---

## 8. Endpoint

### 8.1 Requête

`GET /api/etfs/{ticker}`

- Le ticker est **normalisé** (`trim` puis majuscules) et **validé** : 1 à 10 caractères parmi `A-Z`, `0-9`, `.` et `-`. Sinon, **400** avec la nouvelle exception métier `InvalidTickerException` (`error.etfs.invalid-ticker`).
- La normalisation et la validation sont une règle métier : fonction `Etf.normalizeTicker(raw: String): String` dans le `companion object` de `Etf`. Pas de nouvelle dépendance de validation.
- ETF absent du catalogue : **404** avec `EtfNotFoundException` (`error.etfs.etf-not-found`).

Les deux exceptions héritent de `BusinessException`, selon le modèle du `CLAUDE.md`. `ExceptionController` n'a rien à changer.

### 8.2 Réponse

```json
{
  "ticker": "SPY",
  "exchange": "NYSE",
  "name": "State Street SPDR S&P 500 ETF Trust",
  "currency": "USD",
  "marketData": {
    "lastClose": 766.48,
    "lastCloseDate": "2026-10-19",
    "historyStartDate": "2021-10-12",
    "returns": { "oneYear": 0.142, "threeYears": 0.51, "fiveYears": 0.88, "fiveYearsAnnualized": 0.135 },
    "volatilityOneYear": 0.161,
    "maxDrawdown": { "value": -0.245, "peakDate": "2022-01-03", "troughDate": "2022-10-12" },
    "fiftyTwoWeekRange": { "low": 629.28, "high": 781.62, "position": 0.9 }
  },
  "fetchedAt": "2026-10-20T09:00:00Z",
  "stale": false
}
```

- `fetchedAt` : date de récupération des cours (`null` si jamais récupérés).
- `marketData` vaut `null` si aucun cours n'a jamais pu être récupéré. Dans ce cas, `stale = true`.
- Les champs d'indicateurs peuvent valoir `null` individuellement (historique trop court).

### 8.3 Controller

Dans `EtfController` : `@GetMapping("/etfs/{ticker}")`, qui délègue au service et convertit le résultat avec le mapper. Aucune logique.

---

## 9. Service : `EtfDetailService.retrieveEtf(ticker): EtfDetail`

Un **nouveau service**, pour ne pas mélanger le catalogue et la fiche dans `EtfService` (SRP). Il dépend de `EtfRepository`, `EtfClosingPriceRepository`, `TwelveDataClient` et `Clock`.

**Déroulé** (`@Transactional`) :

1. `normalizedTicker = Etf.normalizeTicker(ticker)` (400 si invalide).
2. Charger l'ETF par ticker, sinon `EtfNotFoundException`.
3. `fetchedAt = findFirstByEtfIdOrderByFetchedAtDesc(etf.id)?.fetchedAt`.
4. **Si les cours ne sont pas périmés** (`ClosingPriceHistory.isStale(fetchedAt, now)` est faux) : charger les cours en base, construire l'historique, renvoyer `EtfDetail(etf, history.marketData(), fetchedAt, stale = false)`.
5. **Sinon**, appeler `fetchDailyClosingPrices(ticker, now − 5 ans − 7 jours)` :
   - **succès** : construire l'historique **à partir des cours reçus**, sans relire la base, puis supprimer les anciens cours de l'ETF (`deleteAllByEtfId`) et insérer en lot ceux de l'historique avec `fetchedAt = now`. Ce sont donc les cours triés et **dédoublonnés par date** (`ClosingPriceHistory.fromUnsorted`) : Twelve Data peut renvoyer une même date deux fois, ce que la contrainte d'unicité `(etf_id, trading_date)` refuserait. Renvoyer `stale = false` ;
   - **`TwelveDataUnavailableException`** : journaliser un `warn` sans la cause, ne rien écrire, charger les cours en base et renvoyer `stale = true`. Si la base n'a aucun cours, `marketData = null`.

Les méthodes privées suivent le découpage de `EtfService` (une méthode par étape).

---

## 10. Affichage attendu côté mobile (proposition, à ajuster)

L'API ne renvoie aucun texte : ces cas sont décrits pour l'équipe Flutter.

| Situation | Signal dans la réponse | Affichage proposé |
|---|---|---|
| Indicateur incalculable | Champ `null`, et `historyStartDate` renseigné | « — » et la mention *« Historique disponible depuis le 12/03/2023 »* |
| Cours jamais récupérés | `marketData = null`, `stale = true` | *« Données de marché momentanément indisponibles »* à la place du bloc |
| Cours périmés | `stale = true` avec des données | Les valeurs, avec un bandeau *« Données au 19/10/2026, mise à jour impossible »* (à partir de `lastCloseDate`) |

Rappel pédagogique pour l'affichage : les rendements passés ne préjugent pas des rendements futurs. Les taux sont des fractions à afficher en pourcentage.

---

## 11. Tests et vérification

Aucun appel réel. Conventions du `CLAUDE.md`.

| Classe | Contenu |
|---|---|
| **`ClosingPriceHistoryTest`** (prioritaire) | Avec des séries construites à la main : chaque indicateur sur un cas simple vérifiable de tête ; clôture de référence un jour de fermeture ; historique trop court (`null`) ; perte maximale nulle sur une série croissante, et dates de sommet et de creux correctes ; position dans la fourchette (bornes et `haut = bas`) ; invariants (liste vide, dates en double) ; `isStale` (moins de 1 jour, exactement 1 jour, plus de 1 jour, jamais récupéré) |
| `EtfTest` | `normalizeTicker` : casse, espaces, caractères invalides, longueur |
| `EtfDetailServiceTest` (MockK) | Cours à jour : aucun appel à Twelve Data. Cours périmés : 1 appel, suppression puis insertion, `stale = false`. Échec de l'API avec cours en base : `stale = true`, aucune écriture. Échec sans cours : `marketData = null`. ETF inconnu : `EtfNotFoundException` |
| `TwelveDataClientTest` | `fetchDailyClosingPrices` : désérialisation des chaînes en `LocalDate` et `BigDecimal`, paramètres de requête (`interval`, `start_date`, `adjust=all`, `order`), erreurs comme pour `fetchEtfs` |
| `EtfMapperTest` | Conversion `EtfDetail` vers DTO, avec et sans `marketData`, avec des indicateurs `null` |
| `EtfControllerTest` | 200 avec le JSON attendu ; ticker en minuscules accepté ; 400 pour un ticker invalide ; 404 pour un ETF inconnu |
| `EtfClosingPriceRepositoryTest` (`@DataJpaTest` sur la base locale, `@AutoConfigureTestDatabase(replace = NONE)`) | `deleteAllByEtfId` ne supprime que les cours de l'ETF visé ; la suppression d'un ETF supprime ses cours (cascade) |

**Vérification manuelle (2 crédits Twelve Data au total)** :
1. **Avant de coder** : 1 appel `time_series` sur SPY avec `adjust=all` et `outputsize=5`, pour vérifier que l'option est acceptée.
2. **À la fin** : `curl http://localhost:8080/api/etfs/spy` renvoie la fiche avec `stale = false` (1 appel). Un second appel immédiat ne déclenche aucun appel à Twelve Data.

---

## 12. Documentation

- **Glossaire** : clôture ajustée, rendement total, rendement annualisé, volatilité annualisée, perte maximale (*max drawdown*), fourchette sur 52 semaines, jour de bourse, historique des clôtures (`ClosingPriceHistory`), avec les conventions de la section 5.3.
- **`CLAUDE.md`** : mentionner l'exception `Double` limitée à la puissance non entière (section 5.3).

## 13. Critères de fin

- [ ] `SPRING_PROFILES_ACTIVE=local ./mvnw test` passe, et Flyway applique la V3.
- [ ] `GET /api/etfs/SPY` renvoie la fiche, et `/api/etfs/spy` la même.
- [ ] `GET /api/etfs/ARKK` renvoie 404, et `GET /api/etfs/SP%20Y` renvoie 400.
- [ ] Un second appel dans la journée ne déclenche aucun appel à Twelve Data.
- [ ] La synchronisation du catalogue reste fonctionnelle : un ETF retiré emporte ses cours.
- [ ] Aucune règle de calcul dans le service ni dans le controller : tout est dans `ClosingPriceHistory`.
- [ ] Quota consommé pendant le développement : 2 crédits.

---

## 14. Ajustements : série de cours pour la courbe du détail

Ajout demandé pendant le cadrage de l'écran mobile du détail (`indice_mobile/docs/plans/plan-implementation-etf-detail.md`) : l'écran affiche une **courbe d'évolution** de l'ETF. Le reste de la fiche est inchangé.

### 14.1 Décisions

| Sujet | Décision |
|---|---|
| Valeur tracée | La **clôture ajustée** en devise de l'ETF (dollars), et non la base 100 : avec le défilement horizontal prévu côté mobile, la valeur d'un jour ne dépend pas de la fenêtre affichée |
| Variation | Chaque point porte aussi sa **variation depuis le début de l'historique** : `clôture / première clôture − 1`. Calculée par le backend, le mobile ne fait que l'afficher (« 512,40 USD · +13,87 % depuis le 12/10/2021 ») |
| Étendue | Tout l'historique stocké, **un point par jour de bourse**, comme la courbe de la comparaison. Il couvre au plus 5 ans (et 7 jours, section 4) : un ETF plus ancien n'est pas affiché depuis sa création, pour garder la même période que les indicateurs et une réponse légère. Un ETF plus récent a un historique plus court, sans traitement particulier |
| Emplacement | Dans `marketData` : la série vaut `null` en même temps que lui, quand aucun cours n'a jamais été récupéré |
| Arrondis | Clôture à 2 décimales, variation à 4 décimales (règles de la section 5.3) |
| Poids | Environ 1 260 points, soit environ 75 Ko de JSON par fiche |

### 14.2 Objet métier

```kotlin
data class PricePoint(val date: LocalDate, val close: BigDecimal, val changeSinceStart: BigDecimal)
```

- Nouvelle méthode `ClosingPriceHistory.pricePoints(): List<PricePoint>`. Exemple : de 450 à 512,40, la variation vaut 0,1387, soit +13,87 %. Le premier point a une variation de 0.
- `MarketData` reçoit le champ `pricePoints: List<PricePoint>`, rempli par `marketData()`.
- Nommage : `PricePoint` plutôt que `ClosingPrice`, qui existe déjà avec une autre forme (`date`, `adjustedClose`, sans arrondi ni variation).

### 14.3 Réponse

`GET /api/etfs/{ticker}` : un champ ajouté dans `marketData`, **aucun changement cassant**.

```json
"marketData": {
  "lastClose": 766.48,
  "…": "…",
  "pricePoints": [
    { "date": "2021-10-12", "close": 450.00, "changeSinceStart": 0.0 },
    { "date": "2024-03-12", "close": 512.40, "changeSinceStart": 0.1387 }
  ]
}
```

- DTO `PricePointResponseDto(date, close, changeSinceStart)` dans `dtos/responses`, et le champ `pricePoints: List<PricePointResponseDto>` dans `MarketDataResponseDto`.
- Mapper `PricePoint.toDto()` dans `EtfDetailMapper`.
- La comparaison n'est pas modifiée : elle garde `rebasedPrices`.

### 14.4 Tests

| Classe | Contenu |
|---|---|
| `ClosingPriceHistoryTest` | `pricePoints` : un point par clôture, dans l'ordre ; premier point à 0 ; variation et arrondis sur un cas vérifiable de tête ; le creux de la perte maximale est le point de plus forte baisse ; `marketData()` contient la série |
| `EtfDetailMapperTest` | Conversion de la série |
| `EtfControllerTest` | `$.marketData.pricePoints[0].date`, `.close`, `.changeSinceStart` dans le JSON |

Tous les tests existants restent verts. Vérification manuelle : `curl http://localhost:8080/api/etfs/spy` renvoie la série (0 ou 1 crédit Twelve Data selon la fraîcheur des cours). Vérifier avant que le port 8080 est libre.

### 14.5 Documentation

- **Glossaire**, section Finance : entrée « Point de cours » (`PricePoint`) avec la variation depuis le début de l'historique ; compléter « Historique des clôtures » pour mentionner la courbe du détail.

### 14.6 Commit

Branche `feat/backend/etf-detail-chart`, à merger en même temps que la PR mobile du détail :

- `✨ : backend - add price history to the etf detail`

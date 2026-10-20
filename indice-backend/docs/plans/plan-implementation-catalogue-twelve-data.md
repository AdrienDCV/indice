# Plan d'implémentation : catalogue d'ETF via Twelve Data

> Les conventions du projet sont définies dans le `CLAUDE.md`, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Il fait suite au plan `plan-implementation-get-etfs-catalogue-eodhd.md`, dont il remplace la source de données.

## Avant de coder

1. **Lis le code existant** du domaine `etf` : la synchronisation du catalogue (`EtfService`, `EtfCatalog`) est déjà en place et testée. On change la **source**, pas la logique.
2. **Présente ton plan** (fichiers créés, modifiés, supprimés) et attends la validation avant d'écrire du code.
3. **Économise le quota Twelve Data** : aucun appel réel dans les tests, et une seule vérification manuelle (voir la section 10).

---

## 1. Objectif

Remplacer EODHD par **Twelve Data** comme source du catalogue d'ETF, et passer sur des **ETF américains** identifiés par leur **ticker**.

L'endpoint `GET /api/etfs` garde le même comportement (pagination, synchronisation à la demande, `stale`), seul le contenu change.

Ce plan prépare le **détail d'un ETF** (`GET /api/etfs/{ticker}`), qui fera l'objet d'un second plan et utilisera aussi Twelve Data.

## 2. Pourquoi ce changement

Résultat du cadrage (questions Q1 à Q33), à retenir :

- **EODHD gratuit** ne fournit que des cours : pas de frais, d'encours ni de composition.
- **Aucune API gratuite** testée (EODHD, Alpha Vantage, Twelve Data, FMP, CoinGecko) ne fournit les fondamentaux (TER, encours, secteurs) des ETF européens. Alpha Vantage les fournit pour les ETF américains uniquement ; Twelve Data les réserve à ses offres Ultra et Enterprise.
- **Twelve Data gratuit** fournit, **pour les ETF américains uniquement** (la Bourse de Paris est payante) : l'annuaire des ETF, la cotation et l'historique des cours. C'est suffisant pour des analyses de performance et de risque, qui seront l'objet du second plan.
- Une seule API pour le catalogue et le détail, avec un quota confortable : **800 crédits par jour, 8 par minute**, 1 crédit par appel pour les endpoints utilisés.

## 3. Hors périmètre

- Le détail d'un ETF et les analyses de performance et de risque (second plan).
- Les ETF européens, les ISIN (option payante chez Twelve Data) et les fondamentaux (TER, encours, composition).
- Alpha Vantage, étudié puis abandonné.
- Toute tâche planifiée.

## 4. Décisions

| Sujet | Décision |
|---|---|
| Source | Twelve Data, offre gratuite. EODHD est entièrement retiré |
| ETF proposés | 10 ETF américains : `SPY`, `QQQ`, `VTI`, `URTH`, `VEA`, `VGK`, `EEM`, `BND`, `GLD`, `SCHD` |
| Identifiant | Le **ticker**. La colonne `isin` est supprimée (migration V2, validée) |
| Liste et pays | Dans `application.yaml` : `etf.catalog.selected-tickers` et `etf.catalog.country` |
| Devise et place | Fournies par Twelve Data, plus de préférence pour l'EUR |
| Règles de synchronisation | Inchangées : rafraîchir, ajouter, retirer, garde-fou, validité de 7 jours, `stale` |

---

## 5. API externe : Twelve Data

**Endpoint** : l'annuaire des ETF, filtré par pays.

```
GET https://api.twelvedata.com/etfs?country=United States
```

- **1 crédit** par appel. Il renvoie environ 11 400 ETF américains, en JSON.
- Chaque ETF sélectionné y apparaît **une seule fois** (vérifié pour les 10 tickers).

**Format de la réponse :**

```json
{
  "data": [
    {
      "symbol": "QQQ",
      "name": "Invesco QQQ Trust, Series 1",
      "currency": "USD",
      "exchange": "NASDAQ",
      "mic_code": "XNMS",
      "country": "United States",
      "figi_code": "…",
      "cfi_code": "…",
      "isin": "request_access_via_add_ons",
      "cusip": "request_access_via_add_ons"
    }
  ],
  "count": 11435,
  "status": "ok"
}
```

- Le champ `isin` n'est pas exploitable sur l'offre gratuite : il est ignoré.
- Les noms peuvent contenir des virgules, sans conséquence en JSON.

**Erreurs** : Twelve Data peut renvoyer une erreur **avec un statut HTTP 200**, sous la forme `{"code": 4xx, "message": "…", "status": "error"}`. Il faut donc vérifier à la fois le statut HTTP et le champ `status` du corps.

**Authentification** : la clé est passée dans l'en-tête `Authorization: apikey <clé>`, plutôt que dans l'URL, pour qu'elle n'apparaisse ni dans l'URL ni dans les messages d'exception. Vérifier ce point lors de la vérification manuelle ; à défaut, utiliser le paramètre `apikey` et appliquer la même vigilance que pour EODHD (ne jamais journaliser l'URL ni la cause).

**Configuration** (`application.yaml`) :

```yaml
twelvedata:
  base-url: https://api.twelvedata.com
  api-token: ${TWELVEDATA_API_TOKEN}

etf:
  catalog:
    country: United States
    selected-tickers:
      - SPY  # SPDR S&P 500
      - QQQ  # Invesco Nasdaq-100
      - VTI  # Vanguard Total Stock Market (marché américain)
      - URTH # iShares MSCI World
      - VEA  # Vanguard FTSE Developed Markets (pays développés hors États-Unis)
      - VGK  # Vanguard FTSE Europe
      - EEM  # iShares MSCI Emerging Markets
      - BND  # Vanguard Total Bond Market (obligations)
      - GLD  # SPDR Gold Shares (or)
      - SCHD # Schwab U.S. Dividend Equity
```

- Supprimer `eodhd.*` et `etf.catalog.selected-isins`.
- En local, la clé est dans `application-local.yaml` (non versionné) sous `twelvedata.api-token`.
- `EtfCatalogProperties` devient `(country: String, selectedTickers: Set<String>)`.

---

## 6. Modifications du code

### 6.1 Objets métier (`etf/models`)

**`Etf`**
- Supprimer `isin`. L'invariant porte désormais sur le ticker : `require(ticker.isNotBlank())`.
- `refreshedFrom(source)` exige le même **ticker** et garde l'`id` : `source.copy(id = id)`.

**`EtfCatalog`**
- `synchronizedWith(source, selectedTickers: Set<String>)` :
  1. garder les ETF dont le ticker est sélectionné ;
  2. `distinctBy { it.ticker }`, par précaution ;
  3. rafraîchir les ETF connus (indexés par ticker), ajouter les nouveaux.
- Supprimer `PREFERRED_CURRENCY` et `PREFERRED_LISTING_FIRST` : un ticker est unique sur sa place.
- `etfsMissingFrom` et `isStale` sont inchangés.

### 6.2 Entité et migration

- `EtfEntity` : supprimer `isin`, et `ticker` devient `@Column(nullable = false, unique = true)`.
- **Migration `V2__identify_etf_by_ticker.sql`**, défensive et validée par l'utilisateur (Q26). Seuls les ISIN des ETF parisiens actuels sont perdus, ETF qui seront de toute façon retirés à la prochaine synchronisation.

  ```sql
  ALTER TABLE etf DROP CONSTRAINT IF EXISTS etf_isin_key;
  ALTER TABLE etf DROP COLUMN IF EXISTS isin;
  ALTER TABLE etf DROP CONSTRAINT IF EXISTS etf_ticker_key;
  ALTER TABLE etf ADD CONSTRAINT etf_ticker_key UNIQUE (ticker);
  ```
- **Ne pas modifier la V1**, déjà appliquée et mergée.

### 6.3 DTOs (`etf/dtos/responses`)

- **Supprimer** `EodhdSymbolDto`.
- **Ajouter** :
  ```kotlin
  data class TwelveDataEtfsDto(
      val data: List<TwelveDataEtfDto>?,
      val status: String?,
  )

  data class TwelveDataEtfDto(
      val symbol: String,
      val name: String,
      val currency: String,
      val exchange: String,
  )
  ```
  Les champs inutiles (`mic_code`, `isin`, `figi_code`…) sont ignorés par Jackson.
- `EtfResponseDto` : supprimer `isin`.

### 6.4 Client (`etf/clients`)

- **Supprimer** `EodhdClient` et `EodhdDataUnavailableException`.
- **Ajouter** `TwelveDataClient`, une classe concrète `@Component` :
  - le constructeur reçoit `RestClient.Builder`, `twelvedata.base-url` et `twelvedata.api-token` ;
  - une méthode publique : `fun fetchEtfs(country: String): List<TwelveDataEtfDto>` ;
  - corps lu avec `.body<TwelveDataEtfsDto>()` ;
  - lève `TwelveDataUnavailableException` (`etf/exceptions`, hérite de `RuntimeException`, message fixe, cause conservée) en cas de :
    - `RestClientException` (réseau, timeout, statut non 2xx, JSON invalide) ;
    - `status` différent de `"ok"` ;
    - `data` nul ou vide ;
  - journalise un `info` à chaque appel, **sans la clé**.

### 6.5 Mappers (`etf/mappers/EtfMapper.kt`)

- `EtfEntity.toModel()`, `Etf.toEntity()`, `Etf.toDto()` : retirer `isin`.
- Remplacer `EodhdSymbolDto.toModelOrNull(fetchedAt)` par `TwelveDataEtfDto.toModel(fetchedAt): Etf`. Il n'y a plus de cas nul, puisque le ticker est toujours présent.

### 6.6 Service (`etf/services/EtfService.kt`)

- Remplacer `EodhdClient` par `TwelveDataClient`, et la constante `EXCHANGE = "PA"` par `etfCatalogProperties.country`.
- `fetchSource` : filtrer sur `selectedTickers` avant la conversion, puis `toModel(fetchedAt)`. Le garde-fou « aucun ETF sélectionné dans la réponse » est conservé.
- Intercepter `TwelveDataUnavailableException` à la place de `EodhdDataUnavailableException`.
- `retrieveEtfs(pageable)`, `retrievePage` et `synchronize` sont inchangés sur le fond.

### 6.7 Controller

Inchangé : `GET /etfs`, avec tri par défaut sur `name`.

---

## 7. Contrat d'API (impact sur le mobile)

- `etfs.content[].isin` **disparaît**. L'identifiant d'un ETF est son `ticker`.
- Les ETF proposés deviennent américains, avec des cours en USD.
- Le reste de la réponse est inchangé.

À signaler dans la description de la PR.

---

## 8. Tests

Aucun appel réel. Arborescence et conventions du `CLAUDE.md`.

| Classe | À faire |
|---|---|
| `EtfTest` | Adapter : invariant sur le ticker, `refreshedFrom` par ticker |
| `EtfCatalogTest` | Adapter au ticker. Supprimer le test de préférence pour l'EUR. Garder la conservation des `id`, l'ajout, le retrait et l'immuabilité |
| `EtfMapperTest` | Adapter. Remplacer les tests de `toModelOrNull` par un test de `TwelveDataEtfDto.toModel` |
| `EtfServiceTest` | Remplacer le client EODHD par `TwelveDataClient`, et les ISIN par des tickers. Mêmes scénarios |
| `TwelveDataClientTest` (remplace `EodhdClientTest`) | Avec `MockRestServiceServer` et une réponse enregistrée dans `src/test/resources/twelvedata/etfs-united-states.json` (quelques ETF) : désérialisation (champs inconnus ignorés) ; exception sur statut HTTP en erreur, JSON invalide, `"status": "error"` avec un HTTP 200, `data` vide ; la clé n'apparaît pas dans le message d'exception ; la clé est envoyée dans l'en-tête `Authorization` |
| `EtfControllerTest` | Adapter le JSON attendu (plus de `isin`) |

Supprimer `EodhdClientTest` et `src/test/resources/eodhd/`.

---

## 9. Documentation

- **Glossaire** :
  - remplacer EODHD et « Symbole » par Twelve Data et « Annuaire des ETF » ;
  - préciser que l'ISIN n'est plus utilisé, et que le **ticker** est l'identifiant ;
  - « ETF sélectionnés » devient `etf.catalog.selected-tickers`.
- **Plan du catalogue EODHD** : ajouter une section **12.9 Passage à Twelve Data** qui renvoie vers ce plan.
- **`CLAUDE.md`** : remplacer les exemples qui citent EODHD (`EodhdClient`, `EodhdSymbolDto`, `EodhdDataUnavailableException`) par leurs équivalents Twelve Data.

---

## 10. Critères de fin

- [ ] `SPRING_PROFILES_ACTIVE=local ./mvnw test` passe, et Flyway applique la V2 sur la base locale.
- [ ] Plus aucune référence à EODHD dans le code ni la configuration (`grep -ri eodhd src` ne renvoie rien).
- [ ] **Vérification manuelle, en un seul appel Twelve Data** : `curl http://localhost:8080/api/etfs` renvoie les 10 ETF américains, sans `isin`, avec `stale = false`. Un second appel immédiat ne déclenche aucun appel à Twelve Data.
- [ ] La clé Twelve Data n'apparaît dans aucun fichier versionné ni dans les logs.
- [ ] Le changement de contrat d'API est signalé dans la PR.

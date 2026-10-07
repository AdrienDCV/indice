# Plan d'implémentation : catalogue d'ETF (`GET /etfs`)

> Les conventions du projet sont définies dans le `CLAUDE.md`, qui fait foi. Ce plan ne décrit que la fonctionnalité.

## Avant de coder

1. **Lis le code existant.** Le projet est quasiment vide : `IndiceApplication.kt`, `application.yaml`, `application-local.yaml` (ignoré par Git), `docker-compose.yml`, et aucune migration Flyway.
2. **Présente ton plan** (fichiers à créer ou modifier, dépendances à ajouter) et attends la validation avant d'écrire du code.
3. En cas de doute, **pose la question** plutôt que de choisir arbitrairement.

---

## 1. Objectif

Exposer `GET /etfs`, qui renvoie le catalogue d'ETF stocké en base. L'URL complète est `/api/etfs`, puisque `context-path: /api`.

Le catalogue est alimenté par l'API EODHD **à la demande**, sans tâche planifiée : c'est la requête de l'utilisateur qui déclenche le rafraîchissement lorsque les données sont périmées.

## 2. Hors périmètre

- Les cours et l'historique des prix des ETF.
- Toute tâche planifiée : ni `@Scheduled`, ni CRON, ni Spring Batch.
- Le délai avant une nouvelle tentative après un échec de l'API.
- Les champs qui ne sont pas fournis par EODHD (frais, éligibilité au PEA…).
- La gestion des requêtes concurrentes lors du premier chargement.

---

## 3. Architecture

Le découpage suit le `CLAUDE.md` : un package par domaine métier, puis un sous-package par couche. Ne crée que les sous-packages qui contiennent au moins un fichier.

```
com.fisa.indice
├── common/
│   └── config/
│       └── ClockConfig.kt                        # bean java.time.Clock (UTC)
└── etf/
    ├── controllers/EtfController.kt
    ├── services/EtfService.kt
    ├── repositories/EtfRepository.kt
    ├── models/
    │   ├── Etf.kt                                # un ETF et sa logique propre
    │   ├── EtfCatalog.kt                         # le catalogue : péremption, sélection, synchronisation
    │   └── RetrievedEtfCatalog.kt                # résultat du service : catalogue + indicateur stale
    ├── entities/EtfEntity.kt
    ├── dtos/responses/
    │   ├── EtfCatalogResponseDto.kt              # réponse de GET /etfs
    │   ├── EtfResponseDto.kt                     # un ETF dans cette réponse
    │   └── EodhdSymbolDto.kt                     # une entrée de la réponse d'EODHD
    ├── mappers/EtfMapper.kt
    ├── clients/EodhdClient.kt                    # appel HTTP à EODHD
    └── exceptions/EodhdDataUnavailableException.kt
```

```
EtfController ◀─ DTO ─▶ EtfService ◀─ EtfEntity ─▶ EtfRepository
                            │      ◀─ EodhdSymbolDto ── EodhdClient
                            │
                    Etf, EtfCatalog   (toute la logique métier)
```

- `EtfCatalog` et `Etf` décident **quoi** faire des données : catalogue périmé ou non, quels ETF retenir, comment les mettre à jour.
- `EtfService` **orchestre** : il charge les données, décide **quand** appeler EODHD, demande au catalogue d'agir, puis persiste et convertit le résultat.
- `EodhdClient` sait **comment** appeler EODHD.

---

## 4. API externe : EODHD

**Endpoint :**

```
GET https://eodhd.com/api/exchange-symbol-list/PA?api_token={token}&fmt=json&type=etf
```

- `PA` désigne Euronext Paris.
- **Un seul appel renvoie tous les ETF de la place**, soit plusieurs centaines d'entrées, pour un coût d'un appel sur le quota.
- Le quota gratuit est de 20 appels par jour. **Aucun appel réel ne doit avoir lieu dans les tests.**

**Format de la réponse : un tableau d'objets**

```json
[
  {
    "Code": "CW8",
    "Name": "Amundi MSCI World UCITS ETF",
    "Country": "France",
    "Exchange": "PA",
    "Currency": "EUR",
    "Type": "ETF",
    "Isin": "LU1681043599"
  }
]
```

- Les noms de champs commencent par une majuscule.
- `Isin` peut être `null`.
- Les valeurs ci-dessus ne servent qu'à illustrer le format.

**Configuration :**

- Dans `application.yaml` :

  ```yaml
  spring:
    http:
      clients:
        connect-timeout: 5s
        read-timeout: 10s

  eodhd:
    base-url: https://eodhd.com/api
    api-token: ${EODHD_API_TOKEN}
  ```

- La valeur réelle du token n'apparaît que dans `application-local.yaml` (déjà ignoré par Git) ou dans la variable d'environnement.
- **Le token ne doit jamais apparaître dans les logs.** Il fait partie de l'URL : ne journalise ni l'URL complète, ni le message des exceptions de `RestClient` (celui d'une `ResourceAccessException` contient l'URL, token compris).

---

## 5. Objets métier (`etf/models`)

Ce sont des `data class` immuables, sans aucune annotation. Elles portent toute la logique de la fonctionnalité et se testent sans mock (voir le point 10.1). Une méthode qui « modifie » un objet renvoie une nouvelle instance via `copy()`.

### 5.1 `Etf`

```kotlin
data class Etf(
    val isin: String,
    val ticker: String,
    val exchange: String,
    val name: String,
    val currency: String,
    val fetchedAt: Instant,
)
```

- **Invariant** : `isin` n'est pas vide (`init { require(isin.isNotBlank()) }`).
- Méthodes métier :

| Méthode | Comportement |
|---|---|
| `fun isSpeculative(): Boolean` | `true` si le nom contient l'un des `SPECULATIVE_KEYWORDS`, sans tenir compte de la casse |
| `fun refreshedFrom(source: Etf): Etf` | Renvoie une copie avec `ticker`, `exchange`, `name`, `currency` et `fetchedAt` de `source`. Exige le même `isin` (`require`) |
| `fun synchronizedAt(at: Instant): Etf` | Renvoie une copie avec `fetchedAt = at` |

- Constante dans le `companion object` : `SPECULATIVE_KEYWORDS` = `leverag`, `short`, `inverse`, `bear`, `2x`, `3x`, `-1x`.

### 5.2 `EtfCatalog`

```kotlin
data class EtfCatalog(val etfs: List<Etf>) {
    fun sortedByName(): List<Etf> = etfs.sortedBy { it.name }
}
```

- `etfs` est une `List` en lecture seule : le catalogue ne se modifie qu'en créant une nouvelle instance.
- `sortedByName()` donne l'ordre d'affichage, utilisé par le mapper vers le DTO.
- Méthodes métier :

| Méthode | Comportement |
|---|---|
| `fun lastSynchronizedAt(): Instant?` | Le `fetchedAt` le plus récent, ou `null` si le catalogue est vide |
| `fun isStaleAt(now: Instant): Boolean` | `true` si le catalogue est vide, ou si `lastSynchronizedAt()` date de **strictement plus de** `TTL` |
| `fun synchronizedWith(source: List<Etf>, now: Instant): EtfCatalog` | Renvoie un nouveau catalogue selon les règles du point 5.3 |

- Constantes dans le `companion object` : `TTL = Duration.ofDays(7)` et `MAX_SIZE = 20`.

### 5.3 Règles de `synchronizedWith`

`source` contient tous les ETF parisiens renvoyés par EODHD, déjà convertis en `Etf` avec `fetchedAt = now`. On ne vide jamais le catalogue.

**Si le catalogue est vide : sélection initiale**

1. Écarter les ETF pour lesquels `isSpeculative()` est vrai.
2. Trier par `ticker` croissant.
3. Supprimer les doublons d'ISIN en gardant la première occurrence (`distinctBy`). Le tri a lieu **avant** cette étape, pour que la sélection ne dépende pas de l'ordre de la réponse d'EODHD.
4. Garder les `MAX_SIZE` premiers : ils forment le nouveau catalogue.

**Si le catalogue est déjà rempli : mise à jour**

1. Indexer `source` par ISIN (`associateBy`).
2. Pour chaque ETF du catalogue, appeler `refreshedFrom` avec son entrée lorsqu'elle existe.
3. Appeler `synchronizedAt(now)` sur **tous** les ETF du catalogue, même ceux absents de `source` : la synchronisation a réussi. Sinon, si aucun ISIN ne correspond, le catalogue resterait périmé et chaque requête rappellerait EODHD, ce qui épuiserait le quota.
4. **N'ajouter aucun nouvel ETF** et **n'en supprimer aucun**.

---

## 6. Autres objets

### 6.1 `EodhdSymbolDto` (`etf/dtos`)

```kotlin
data class EodhdSymbolDto(
    @JsonProperty("Code") val code: String,
    @JsonProperty("Name") val name: String,
    @JsonProperty("Exchange") val exchange: String,
    @JsonProperty("Currency") val currency: String,
    @JsonProperty("Isin") val isin: String?,
)
```

- `@JsonProperty` s'importe depuis `com.fasterxml.jackson.annotation` : avec **Jackson 3** (`tools.jackson.*`), les annotations ont conservé leur ancien package.
- Les champs inutiles (`Country`, `Type`) sont ignorés sans configuration : Jackson 3 et Spring Boot désactivent `FAIL_ON_UNKNOWN_PROPERTIES` par défaut. Le test du point 10.4 le vérifie.
- C'est le DTO **entrant** qui reflète le format d'EODHD. Il est produit par `EodhdClient`, converti en `Etf` par le mapper, et **n'est jamais renvoyé par l'API Indice**.

### 6.2 `EodhdClient` (`etf/clients`)

- Une classe concrète `@Component`, **sans interface**.
- Le constructeur reçoit un `RestClient.Builder`, ainsi que `eodhd.base-url` et `eodhd.api-token` via `@Value`. Le `RestClient` est construit une fois, avec `baseUrl`.
- Une seule méthode publique : `fun fetchEtfs(exchange: String): List<EodhdSymbolDto>`.
- Elle journalise un `info` à chaque appel (« Appel EODHD pour la place PA »), **sans l'URL**.
- Lève une **`EodhdDataUnavailableException`** dans les cas suivants :
  - erreur réseau ou timeout ;
  - statut non 2xx ;
  - JSON invalide ;
  - **réponse vide** : une place sans aucun ETF signale un incident côté EODHD, pas un catalogue vide.
- **Spring Boot 4** : le bean `RestClient.Builder` et les timeouts `spring.http.clients.*` ne sont auto-configurés que si **`spring-boot-starter-restclient`** est présent. Ce starter n'est pas dans le `pom.xml` (voir la section 9).

### 6.3 `EodhdDataUnavailableException` (`etf/exceptions`)

- Hérite de `RuntimeException`. Son message est fixe et ne contient pas l'URL. La cause d'origine peut être conservée.
- C'est une exception technique, levée par `EodhdClient` et **interceptée par `EtfService`**.
- Elle n'est jamais propagée jusqu'au controller, et il n'y a donc **rien à ajouter dans un `@RestControllerAdvice`**.

### 6.4 Entité `EtfEntity` (`etf/entities`)

| Champ | Type Kotlin | Contraintes |
|---|---|---|
| `isin` | `String` (`val`) | **Clé primaire** |
| `ticker` | `String` (`var`) | non nul |
| `exchange` | `String` (`var`) | non nul |
| `name` | `String` (`var`) | non nul |
| `currency` | `String` (`var`) | non nul |
| `fetchedAt` | `Instant` (`var`) | non nul, date de la dernière synchronisation réussie |

- Simple reflet de la table, **sans aucune logique**.
- `@Table(name = "etf")` est obligatoire : sans cette annotation, Hibernate attendrait une table `etf_entity`.
- `equals` et `hashCode` sont basés sur `isin`.
- Les plugins Kotlin `jpa` et `all-open` sont déjà configurés dans le `pom.xml`.
- **Migration Flyway** : `src/main/resources/db/migration/V1__create_etf_table.sql`. C'est la première migration du projet, et le dossier `db/migration` est à créer.

  ```sql
  CREATE TABLE etf (
      isin       VARCHAR(12)  PRIMARY KEY,
      ticker     VARCHAR(20)  NOT NULL,
      exchange   VARCHAR(10)  NOT NULL,
      name       VARCHAR(255) NOT NULL,
      currency   VARCHAR(10)  NOT NULL,
      fetched_at TIMESTAMPTZ  NOT NULL
  );
  ```

### 6.5 DTO de réponse (`etf/dtos`)

```kotlin
data class EtfCatalogResponseDto(
    val data: List<EtfResponseDto>,
    val fetchedAt: Instant?,   // EtfCatalog.lastSynchronizedAt()
    val stale: Boolean,        // true si le rafraîchissement nécessaire a échoué
)

data class EtfResponseDto(
    val isin: String,
    val ticker: String,
    val exchange: String,
    val name: String,
    val currency: String,
)
```

**Exemple de réponse :**

```json
{
  "data": [
    { "isin": "LU1681043599", "ticker": "CW8", "exchange": "PA", "name": "Amundi MSCI World UCITS ETF", "currency": "EUR" }
  ],
  "fetchedAt": "2026-10-07T08:00:00Z",
  "stale": false
}
```

- La liste `data` suit l'ordre de `EtfCatalog.sortedByName()`, dans tous les cas, y compris avec `stale = true`.
- `fetchedAt` est sérialisé au format ISO-8601, comme le fait Jackson 3 par défaut.

### 6.6 `EtfMapper.kt` (`etf/mappers`)

Des fonctions d'extension uniquement, qui recopient des champs et ne contiennent aucune logique métier :

| Fonction | Sens |
|---|---|
| `fun EtfEntity.toModel(): Etf` | entité → métier |
| `fun Etf.toEntity(): EtfEntity` | métier → entité |
| `fun Etf.toDto(): EtfResponseDto` | métier → DTO |
| `fun RetrievedEtfCatalog.toDto(): EtfCatalogResponseDto` | métier → DTO (appelé par le controller) |
| `fun EodhdSymbolDto.toModelOrNull(fetchedAt: Instant): Etf?` | DTO externe → métier |

- `toModelOrNull` renvoie `null` lorsque `isin` est `null` ou vide : une entrée sans ISIN ne peut pas devenir un `Etf`, car elle violerait son invariant. Ce n'est pas un filtre métier.
- Il n'existe **aucune** conversion directe entre `EodhdSymbolDto` ou `EtfResponseDto` et `EtfEntity`.

---

## 7. Orchestration : `EtfService.retrieveEtfs(): RetrievedEtfCatalog`

C'est la méthode publique appelée par le controller. Le service ne contient **aucune règle métier** : il délègue à `EtfCatalog`.

Constante dans le `companion object` : `EXCHANGE = "PA"`.

### 7.1 Déroulé

1. Charger le catalogue : `EtfCatalog(etfRepository.findAll().map { it.toModel() })`.
2. `now = Instant.now(clock)`, avec le `Clock` injecté.
3. **Si `catalog.isStaleAt(now)` est faux** : renvoyer `RetrievedEtfCatalog(catalog, stale = false)`. Aucun appel à EODHD.
4. **Sinon** : faire **un seul** appel à `eodhdClient.fetchEtfs(EXCHANGE)`.
   - **En cas de succès** :
     1. convertir la réponse : `symbols.mapNotNull { it.toModelOrNull(now) }` ;
     2. `val synchronized = catalog.synchronizedWith(source, now)` ;
     3. enregistrer avec `etfRepository.saveAll(synchronized.etfs.map { it.toEntity() })` ;
     4. renvoyer `RetrievedEtfCatalog(synchronized, stale = false)`.
   - **En cas d'`EodhdDataUnavailableException`** : journaliser un `warn` **sans le message de la cause**, **ne rien écrire**, et renvoyer `RetrievedEtfCatalog(catalog, stale = true)`. Si la base est vide, le catalogue est vide et `lastSynchronizedAt()` vaut `null`.

### 7.2 Transactions

- `retrieveEtfs()` est annoté **`@Transactional`**, puisqu'il peut écrire en base.
- **Conséquence assumée** : lors d'un rafraîchissement, l'appel HTTP à EODHD a lieu pendant la transaction, et une connexion à la base reste ouverte pendant la durée de l'appel (10 s au maximum, au plus une fois par semaine). C'est acceptable à l'échelle du projet.
- `EodhdClient` n'est pas transactionnel : l'interception de `EodhdDataUnavailableException` dans le service ne marque donc pas la transaction pour un rollback.
- Les écritures ne doivent pas être déplacées dans une autre méthode du même service annotée `@Transactional` : l'annotation serait ignorée, car un appel interne à la classe ne passe pas par le proxy de Spring.
- `saveAll` sur des entités dont l'identifiant est renseigné fait un `merge` : Hibernate insère les nouveaux ETF et met à jour les existants, ce qui convient ici.

---

## 8. Controller (`etf/controllers`)

- `@GetMapping("/etfs")` renvoie `200` avec `etfService.retrieveEtfs().toDto()` : le controller convertit l'objet métier renvoyé par le service en `EtfCatalogResponseDto`.
- Aucune logique, aucun `try/catch`.

---

## 9. Dépendances

À annoncer avant de les ajouter, conformément au `CLAUDE.md` :

- **`spring-boot-starter-restclient`** : fournit l'auto-configuration de `RestClient.Builder` et des timeouts. Sans lui, Spring Boot 4 n'injecte pas de builder.
- **`io.mockk:mockk-jvm`** (scope `test`) : pour les tests du service.

Aucune autre dépendance n'est nécessaire. En particulier, `springmockk` est inutile (voir le point 10.5), et `MockRestServiceServer` est déjà fourni par `spring-test`.

---

## 10. Tests attendus

Suis les conventions du `CLAUDE.md` : arborescence miroir de `src/main` (par exemple `etf/models/EtfCatalogTest.kt`), noms entre backticks, structure Given / When / Then, un comportement par test.

### 10.1 `EtfTest` et `EtfCatalogTest` : tests unitaires purs, sans mock

**`EtfTest`**

| # | Situation | Résultat attendu |
|---|---|---|
| 1 | ISIN vide | La construction lève une `IllegalArgumentException` |
| 2 | Nom contenant un mot-clé spéculatif, quelle que soit la casse (« Daily Leveraged », « SHORT ») | `isSpeculative()` est vrai |
| 3 | Nom ordinaire | `isSpeculative()` est faux |
| 4 | `refreshedFrom` avec le même ISIN | La copie reprend tous les champs et le `fetchedAt` de `source`. L'instance d'origine est inchangée |
| 5 | `refreshedFrom` avec un autre ISIN | Lève une `IllegalArgumentException` |

**`EtfCatalogTest`**

| # | Situation | Résultat attendu |
|---|---|---|
| 1 | Catalogue vide | `isStaleAt` est vrai, `lastSynchronizedAt()` est `null` |
| 2 | Dernière synchronisation il y a moins de 7 jours | `isStaleAt` est faux |
| 3 | Dernière synchronisation il y a exactement 7 jours | `isStaleAt` est faux |
| 4 | Dernière synchronisation il y a plus de 7 jours | `isStaleAt` est vrai |
| 5 | Plusieurs `fetchedAt` différents | `lastSynchronizedAt()` renvoie le plus récent |
| 6 | Sélection initiale | Les ETF spéculatifs sont écartés, le tri se fait par `ticker` et la limite de 20 est respectée |
| 7 | Sélection initiale avec des ISIN en double, dans deux ordres de `source` différents | La même sélection dans les deux cas |
| 8 | Mise à jour | Les ETF présents dans `source` sont rafraîchis. Aucun ajout ni suppression. Tous ont `fetchedAt = now`, y compris ceux absents de `source` |
| 9 | `sortedByName()` | Les ETF sont triés par nom |
| 10 | `synchronizedWith` | Le catalogue d'origine est inchangé |

### 10.2 `EtfMapperTest`

- `toModelOrNull` renvoie `null` pour un `isin` nul ou vide, et un `Etf` correct sinon.
- Un aller-retour `Etf → EtfEntity → Etf` conserve tous les champs.

### 10.3 `EtfServiceTest` : tests unitaires avec MockK et un `Clock` fixe

La logique métier est déjà couverte au point 10.1 : ici, on ne teste que l'orchestration.

| # | Situation | Résultat attendu |
|---|---|---|
| 1 | Catalogue à jour | `EodhdClient` n'est **pas** appelé, `saveAll` non plus. `stale = false` |
| 2 | Catalogue périmé | `EodhdClient` est appelé **une seule fois**, `saveAll` reçoit le catalogue synchronisé. `stale = false` |
| 3 | Réponse EODHD contenant des entrées sans ISIN | Ces entrées sont ignorées sans erreur |
| 4 | Catalogue périmé et `EodhdDataUnavailableException` | `saveAll` n'est pas appelé. Les données en base sont renvoyées, `stale = true` |
| 5 | Table vide et `EodhdDataUnavailableException` | Liste vide, `fetchedAt = null`, `stale = true` |

### 10.4 `EodhdClientTest`

- Le client est construit avec un `RestClient.Builder` lié à un `MockRestServiceServer` (`MockRestServiceServer.bindTo(builder).build()`), sans contexte Spring. **Aucun appel réel.**
- La désérialisation d'une réponse JSON enregistrée dans `src/test/resources` est correcte, `Isin` nul et champs inconnus compris.
- Un statut HTTP d'erreur, un JSON invalide ou une réponse vide (`[]`) lèvent `EodhdDataUnavailableException`.
- Le message de l'exception ne contient pas le token.

### 10.5 `EtfControllerTest`

- Avec `@WebMvcTest(EtfController::class)`. Le service simulé est un `mockk<EtfService>()` déclaré comme bean dans une `@TestConfiguration` interne : MockK ne fournit pas d'équivalent à `@MockitoBean`.
- Vérifier le statut `200` et un JSON conforme à la section 6.5 (`data`, `fetchedAt` au format ISO-8601, `stale`).

---

## 11. Critères de fin

- [ ] `./mvnw test` passe.
- [ ] Avec le profil `local` et un token valide, `curl http://localhost:8080/api/etfs` renvoie au plus 20 ETF, sans ETF à effet de levier ni « short ».
- [ ] Un deuxième appel immédiat ne déclenche aucun appel à EODHD : le log `info` d'`EodhdClient` n'apparaît qu'une fois.
- [ ] Le token EODHD n'apparaît dans aucun fichier versionné, ni dans les logs.
- [ ] Aucune entité JPA ni aucun objet métier n'est exposé par l'API.
- [ ] `EtfService` ne contient aucune règle métier : péremption, sélection et mise à jour sont dans `EtfCatalog` et `Etf`.

---

## 12. Ajustements post-développement

Cette section décrit ce qui a été révisé ou précisé pendant ou après l'implémentation. Elle prime sur les sections précédentes en cas d'écart.

### 12.1 Découpage de `EtfService.retrieveEtfs()`

Écrite telle que décrite au point 7.1, la méthode cumulait plusieurs responsabilités : chargement, appel à EODHD avec gestion de l'échec, synchronisation et enregistrement. Elle a été découpée en trois méthodes privées, et ne fait plus qu'enchaîner les étapes :

```kotlin
@Transactional
fun retrieveEtfs(): RetrievedEtfCatalog {
    val catalog = loadCatalog()
    val now = Instant.now(clock)
    if (!catalog.isStaleAt(now)) return RetrievedEtfCatalog(catalog, stale = false)

    val source = fetchSource(now) ?: return RetrievedEtfCatalog(catalog, stale = true)
    return RetrievedEtfCatalog(save(catalog.synchronizedWith(source, now)), stale = false)
}
```

| Méthode privée | Rôle |
|---|---|
| `loadCatalog(): EtfCatalog` | Lit la base et convertit en objet métier |
| `fetchSource(fetchedAt): List<Etf>?` | Appelle EODHD et convertit la réponse. Renvoie `null` et journalise un `warn` si EODHD est indisponible |
| `save(catalog): EtfCatalog` | Enregistre le catalogue et le renvoie |

Ces méthodes ne sont pas annotées `@Transactional` : elles s'exécutent dans la transaction de `retrieveEtfs()` (voir le point 7.2).

### 12.2 Le service renvoie un objet métier

Le plan initial faisait renvoyer un DTO (`EtfCatalogResponseDto`) par `EtfService`. Règle corrigée dans le `CLAUDE.md` : **une méthode de service reçoit et renvoie des objets métier**, et c'est le controller qui fait la conversion DTO ⇄ objet métier via le mapper.

- L'indicateur `stale` ne décrit pas le catalogue lui-même, mais le résultat de la consultation (synchronisation nécessaire et échouée). Il est porté par un nouvel objet métier, `RetrievedEtfCatalog(catalog: EtfCatalog, stale: Boolean)`, renvoyé par le service.
- Le mapper `EtfCatalog.toDto(stale)` devient `RetrievedEtfCatalog.toDto()`, appelé par `EtfController`.
- Tests : `EtfServiceTest` vérifie l'objet métier renvoyé, `EtfControllerTest` simule un `RetrievedEtfCatalog`, et `EtfMapperTest` gagne un test de conversion (tri par nom, `fetchedAt`, `stale`). Total : 31 tests ajoutés.

### 12.3 Identifiant technique à la place de l'ISIN comme clé primaire

L'ISIN identifie un fonds, pas sa cotation : le même ETF peut être coté sur plusieurs places. Il vient aussi d'une source externe, et servira de clé étrangère aux futures tables (performances, portefeuille…). La clé primaire devient donc un identifiant technique.

- **`Etf`** : nouveau champ `val id: UUID = UUID.randomUUID()`, généré à la création de l'objet métier. Il est placé en dernier pour ne pas imposer d'arguments nommés. `refreshedFrom` conserve l'`id` de l'ETF existant.
- **`EtfEntity`** : `@Id val id: UUID`. `isin` est `@Column(nullable = false, unique = true)`. `equals` et `hashCode` sont basés sur `id`.
- **`EtfRepository`** : `JpaRepository<EtfEntity, UUID>`.
- **Mappers** : `id` est recopié dans les deux sens entre entité et objet métier. Il n'est **pas exposé** dans `EtfResponseDto` : l'API continue d'identifier les ETF par leur ISIN.
- **Migration** : une V2 (`use_uuid_as_etf_primary_key`) a d'abord été écrite. Les migrations n'ayant jamais été commitées, elle a ensuite été **fusionnée dans la V1**, à la demande de l'utilisateur et après remise à zéro de l'historique Flyway local. `V1__create_etf_table.sql` crée directement `id UUID PRIMARY KEY` et la contrainte `etf_isin_key UNIQUE (isin)`, avec `CREATE TABLE IF NOT EXISTS`.
- **Rapprochement avec EODHD** : inchangé, toujours par ISIN. Seuls les ETF ajoutés au catalogue reçoivent un nouvel `id`.
- **Tests** : un `id` différent est généré pour chaque nouvel ETF ; `refreshedFrom` conserve l'`id` ; la synchronisation d'un catalogue rempli conserve les `id` existants. Total : 32 tests ajoutés.

### 12.4 Catalogue défini par une liste d'ISIN

La sélection automatique (« 20 premiers ETF non spéculatifs par ordre de ticker ») posait deux problèmes : elle donnait des ETF peu connus, sans intérêt pédagogique, et le catalogue restait figé, y compris avec des ETF retirés de la cote. **Elle est remplacée par une liste d'ISIN choisie à la main.** Le principe d'un seul appel à EODHD par synchronisation est conservé : la réponse est simplement filtrée en mémoire.

**Règles** (remplacent les points 5.1 à 5.3 sur ce sujet)
- **La liste est dans `application.yaml`**, pas dans le code (`etf.catalog.selected-isins`, un ISIN par ligne avec un commentaire). Elle couvre MSCI World, S&P 500, Nasdaq-100, CAC 40, STOXX Europe 600 et marchés émergents, en version classique et éligible au PEA.
- `EtfCatalogProperties` (`etf/config/`, `@ConfigurationProperties`) lit la liste dans un `Set<String>`. `@ConfigurationPropertiesScan` est ajouté sur `IndiceApplication`.
- `EtfService` récupère ce `Set` et le passe à `EtfCatalog`. L'objet métier ne dépend donc ni de Spring ni de la configuration. Un objet métier dédié (`EtfSelection`) a été envisagé puis retiré : un simple `Set<String>` suffit.
- `synchronizedWith(source, selectedIsins)` produit **exactement** les ETF sélectionnés présents dans `source` :
  - ETF déjà connu : rafraîchi avec `refreshedFrom`, son `id` est conservé ;
  - ETF sélectionné absent de la base : ajouté ;
  - ETF en base absent de la réponse : **retiré**, car on ne propose pas une donnée qui n'existe plus.
- Un ISIN coté plusieurs fois sur la place : on garde la cotation en **EUR**, puis le plus petit ticker. Le résultat ne dépend pas de l'ordre de la réponse.
- `etfsMissingFrom(other)` liste les ETF à supprimer.
- **Garde-fou** : si la réponse EODHD ne contient aucun ETF sélectionné, la synchronisation est considérée comme une panne. Rien n'est écrit ni supprimé, et l'API renvoie les données en base avec `stale = true`. Une réponse partielle ou anormale ne peut donc pas vider le catalogue.
- Il n'y a plus de distinction entre premier chargement et rafraîchissement, ni de limite de taille.

**Code supprimé** : `Etf.isSpeculative()`, `SPECULATIVE_KEYWORDS`, `Etf.synchronizedAt()` (la date vient désormais de `source`), `EtfCatalog.MAX_SIZE`, et le paramètre `now` de `synchronizedWith` (remplacé par `selectedIsins`).

**Optimisations**
- `EtfService` filtre la réponse par ISIN **avant** de la convertir en objets métier (`asSequence().filter { … }.mapNotNull { … }`) : seuls la dizaine d'ETF sélectionnés sont instanciés, au lieu de plusieurs centaines d'objets et d'UUID.
- Recherches en temps constant : la liste des ISIN sélectionnés est un `Set`, les ETF connus sont indexés par ISIN (`associateBy`), et les `id` restants sont rangés dans un `HashSet` pour calculer les suppressions.
- Les suppressions se font en **une seule requête** (`deleteAllByIdInBatch`), uniquement s'il y en a.
- Le traitement complet n'a lieu qu'une fois tous les 7 jours au maximum. Les autres requêtes se limitent à une lecture de la table.

**Tests** : `EtfCatalogTest` couvre le filtrage, la préférence pour la cotation en EUR quel que soit l'ordre, l'ajout, le rafraîchissement avec conservation de l'`id`, la suppression et `etfsMissingFrom`. `EtfServiceTest` couvre la suppression en base et le garde-fou.

**Données existantes** : la base locale contient les 20 ETF de l'ancienne sélection automatique, dont un seul (`LU1681048804`) figure dans la liste. À la prochaine synchronisation, les 19 autres seront supprimés et les ETF de la liste ajoutés.

**À vérifier au premier lancement avec un vrai token** : que chaque ISIN de la liste figure bien dans la réponse EODHD pour Paris. Un ISIN absent n'est pas une erreur : l'ETF n'apparaît simplement pas dans le catalogue.

### 12.5 Pagination de `GET /etfs`

Règle ajoutée au `CLAUDE.md` : tout endpoint de listing est paginé.

- **Requête** : `GET /etfs?page=0&size=20&sort=name,asc`. Par défaut, page 0, 20 éléments, tri par nom (`@PageableDefault(size = 20, sort = ["name"])`). La taille est plafonnée à 100 (`spring.data.web.pageable.max-page-size`).
- **Réponse** :

  ```json
  {
    "etfs": { "content": [ { "isin": "…", "ticker": "…", "exchange": "PA", "name": "…", "currency": "EUR" } ],
              "page": 0, "size": 20, "totalElements": 12, "totalPages": 1 },
    "fetchedAt": "2026-10-07T09:41:06Z",
    "stale": false
  }
  ```
  `PageResponseDto<T>` et son mapper générique `Page<T>.toDto(transform)` sont dans `common/`, pour être réutilisés par les futurs listings.
- **Service** : `retrieveEtfs(pageable): RetrievedEtfCatalog`, où `RetrievedEtfCatalog(etfs: Page<Etf>, lastSynchronizedAt, stale)`.
  - **Catalogue à jour** (cas courant) : deux requêtes légères. `findFirstByOrderByFetchedAtDesc()` donne la date de dernière synchronisation, puis `findAll(pageable)` lit la page en SQL. Le catalogue complet n'est plus chargé.
  - **Catalogue périmé** : la synchronisation charge tout le catalogue (borné par la liste d'ISIN), écrit en base, puis la page est lue avec `findAll(pageable)`.
- **Objet métier** : la péremption devient `EtfCatalog.isStale(lastSynchronizedAt, now)` (fonction du `companion object`), puisqu'on ne charge plus le catalogue pour la vérifier. `isStaleAt`, `lastSynchronizedAt()` et `sortedByName()` sont supprimés : le tri est fait en base.
- **Tri invalide** : `sort=foo` levait une `PropertyReferenceException`, renvoyée en 500. `ExceptionController` la traduit désormais en 400 (`error.pagination.invalid-sort`), sans exposer le nom de l'entité.
- **Vérifié manuellement** sur la base locale (12 ETF) : pagination par défaut, `page=1&size=5` (3 pages), `size=500` ramené à 100, `sort=ticker,desc`, `sort=foo` en 400. Aucun appel à EODHD (catalogue à jour).
- **Tests** : `PageMapperTest`, `EtfControllerTest` (paramètres et valeurs par défaut), `EtfServiceTest` (réécrit : le chemin « à jour » ne charge plus tout le catalogue), `EtfMapperTest`, `ExceptionControllerTest` (tri invalide).

### 12.6 Pistes étudiées puis écartées

- **Use cases** (une classe par cas d'usage, par exemple `RetrieveEtfCatalog`, à la place de `EtfService`) : compatibles avec l'architecture 3-tiers, mais jugés inutiles à l'échelle du projet. On reste sur des services (KISS).
- **`operator fun invoke`** : aucun endroit du code de cette fonctionnalité n'y gagne en lisibilité. La règle d'usage a été ajoutée au `CLAUDE.md` : permis pour une fabrique dans un `companion object`, mais pas sur les services, ni lorsque le nom de la méthode porte une information utile (`fetchEtfs`).

### 12.7 Précisions d'implémentation

- **`EodhdDataUnavailableException`** : son message est fixe (« EODHD data is unavailable ») et sa cause est optionnelle. Une réponse vide est signalée sans cause.
- **Erreurs interceptées par `EodhdClient`** : `RestClientException` couvre à la fois les erreurs réseau, les statuts non 2xx et le JSON invalide. Une seule clause `catch` suffit.
- **MockK** : la version est déclarée dans la propriété Maven `mockk.version` (1.14.11), car elle n'est pas gérée par Spring Boot.
- **`application-local.yaml`** : la clé `eodhd.api-token` y est ajoutée avec la valeur `CHANGE_ME`, à remplacer par un token réel. Ce fichier n'est pas versionné.
- **Sous-packages de DTOs** : les DTOs sont rangés dans `dtos/requests/` ou `dtos/responses/` selon leur rôle HTTP (règle ajoutée au `CLAUDE.md`). Les trois DTOs de cette fonctionnalité sont des réponses, y compris `EodhdSymbolDto`, qui décrit la réponse d'EODHD.
- **Migration V1** : `CREATE TABLE IF NOT EXISTS etf`, conformément à la règle des scripts défensifs ajoutée au `CLAUDE.md`.
- **Baseline Flyway** : `baseline-version: 0` est ajouté sous `spring.flyway` dans `application.yaml` et `application-local.yaml`. Avec `baseline-on-migrate: true` et la valeur par défaut (1), Flyway sauterait la V1 sur une base non vide sans historique.
- **Gestion des erreurs** : `BusinessException`, `ErrorResponseDto` et `ExceptionController` (`@RestControllerAdvice`) sont ajoutés dans `common/`, avec `ExceptionControllerTest` (3 tests). Ils ne changent rien au comportement de `GET /etfs` : `EodhdDataUnavailableException` reste une exception technique interceptée par le service, mais une erreur inattendue renvoie désormais un 500 au format uniforme (`error.unexpected`) au lieu de la réponse par défaut de Spring.
- **Glossaire** : les termes de cette fonctionnalité (catalogue, synchronisation, périmé / `stale`, symbole EODHD…) sont définis dans `docs/glossaire.md`.

### 12.8 Résultats et limites constatées

- **Tests** : 35 tests ajoutés (`EtfTest` 4, `EtfCatalogTest` 11, `EtfMapperTest` 4, `EtfServiceTest` 7, `ExceptionControllerTest` 3, `EodhdClientTest` 5, `EtfControllerTest` 1). Avec `SPRING_PROFILES_ACTIVE=local`, ils passent tous, de même que le test préexistant `IndiceApplicationTests`. Ce dernier vérifie au passage la migration V1 et le mapping de `EtfEntity` sur la base Docker.
- **`./mvnw test` sans profil** : `IndiceApplicationTests` échoue, car `${SPRING_DATASOURCE_URL}` n'est pas défini. Ce problème existait avant cette fonctionnalité et reste à traiter.
- **Vérification manuelle** : faite avec un token invalide uniquement. L'API renvoie `{"data":[],"fetchedAt":null,"stale":true}`, et le token n'apparaît pas dans les logs. Le cas nominal, avec un token valide, reste à vérifier (voir la section 11).
- **Consommation du quota** : tant que la base est vide et qu'EODHD échoue, **chaque requête** rappelle EODHD (observé lors du test manuel). Le délai avant une nouvelle tentative est hors périmètre (section 2), mais il faudra le traiter avant une mise en production : 20 requêtes suffisent à épuiser le quota journalier.
- **Sélection des ETF** : résolu par la liste d'ISIN (voir le point 12.4).

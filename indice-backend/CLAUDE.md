# CLAUDE.md — Indice Backend

## Contexte

**Indice** est une application mobile pédagogique qui aide les débutants (étudiants, jeunes actifs) à comprendre l'investissement financier, en particulier les **ETF**. Ce dépôt est l'**API REST** qui alimente l'application Flutter (`../indice_mobile`).

Modules fonctionnels :
1. **Apprendre** : ressources pédagogiques (texte, image, vidéo) sur l'investissement et les ETF.
2. **Comparer** : fiches détaillées d'ETF et analyse comparative sur les indicateurs clés (frais, performance, volatilité, exposition…).
3. **Construire** *(optionnel, plus tard)* : portefeuille fictif d'ETF. **Ne rien implémenter pour ce module sans demande explicite.**

Contraintes métier non négociables :
- Aucune transaction réelle, aucune connexion bancaire ou courtier.
- L'API **ne produit pas de conseil en investissement** : elle compare et explique. Les données et libellés restent factuels et neutres (pas de « achetez », « meilleur placement »…).

Objets métier principaux : `Etf`, `RessourcePedagogique`, `Media` (image ou vidéo, type déduit de l'extension du fichier/lien).

Vocabulaire financier, métier et technique : voir `docs/glossaire.md`. Tout nouveau terme introduit dans le code ou un plan y est ajouté. Les plans d'implémentation sont dans `docs/plans/`.

## Stack

Kotlin · Java 25 · Spring Boot 4 (Web MVC, Data JPA, Batch) · PostgreSQL 17 · Flyway · Maven · JUnit 5

## Commandes

```bash
docker compose up -d                                        # Base PostgreSQL locale
./mvnw spring-boot:run -Dspring-boot.run.profiles=local     # Lancer l'API (http://localhost:8080/api)
./mvnw test                                                 # Tous les tests
./mvnw test -Dtest=EtfServiceTest                           # Une classe de test
```

## Principes généraux

- **KISS** : la solution la plus simple qui répond au besoin. Pas d'abstraction « au cas où ».
- **YAGNI** : n'implémenter que ce qui est demandé. Pas d'endpoint, de champ, de paramètre ou de couche spéculatifs. Une interface n'est créée que s'il existe plusieurs implémentations ou un besoin réel de substitution.
- **SOLID** :
  - *S* — une classe = une responsabilité (controller ≠ service ≠ repository ≠ mapper).
  - *O* — étendre par composition / nouveaux types plutôt qu'en multipliant les `when`/`if` sur un type.
  - *L* — une implémentation respecte le contrat de son abstraction.
  - *I* — interfaces petites et ciblées.
  - *D* — injection par constructeur uniquement ; dépendre d'abstractions là où ça apporte quelque chose.
- **DRY raisonné** : factoriser à partir de la 3e duplication réelle, pas avant.
- Nommage explicite, fonctions courtes, pas de commentaires qui paraphrasent le code. Code et identifiants en **anglais** ; messages destinés à l'utilisateur final en **français**.
- Pas de code mort, pas de `TODO` laissés sans le signaler.

## Façon de travailler

- Lire le code existant avant d'écrire, et s'aligner sur ses conventions.
- Changements petits et ciblés ; ne pas refactorer hors du périmètre demandé (le proposer plutôt).
- **Ne pas ajouter de dépendance** sans l'annoncer et le justifier.
- Toute nouvelle logique métier est livrée **avec ses tests unitaires**. Lancer `./mvnw test` avant d'annoncer qu'une tâche est terminée.
- Ne jamais commiter sans demande. Commits et pull requests : voir `../CLAUDE.md` (scope `backend`).
- Aucun secret en dur hors `application-local.yaml` ; utiliser les variables d'environnement.

## Architecture (package by feature, puis par couche)

Premier niveau : un package par **domaine métier**. Second niveau : un sous-package par **couche**, chaque domaine pouvant regrouper plusieurs notions (ex. `Etf`, `EtfPerformance`, `EtfAllocation`…).

```
com.fisa.indice
├── common/
│   ├── config/
│   ├── controllers/        # ExceptionController (@RestControllerAdvice)
│   ├── dtos/responses/     # ErrorResponseDto
│   └── exceptions/         # BusinessException
├── etf/
│   ├── controllers/        # EtfController, EtfComparisonController…
│   ├── services/           # EtfService, EtfComparisonService…
│   ├── repositories/       # EtfRepository, EtfPerformanceRepository…
│   ├── models/             # Etf, EtfPerformance… (objets métier, portent la logique)
│   ├── entities/           # EtfEntity, EtfPerformanceEntity… (entités JPA)
│   ├── dtos/
│   │   ├── requests/       # corps de requêtes : CreateEtfRequestDto…
│   │   └── responses/      # corps de réponses : EtfResponseDto, EodhdSymbolDto…
│   ├── mappers/            # EtfMapper.kt (DTO <-> métier <-> entité)
│   ├── clients/            # appels aux API externes (EodhdClient…), utilisés par les services uniquement
│   ├── config/             # @ConfigurationProperties du domaine (EtfCatalogProperties…)
│   └── exceptions/         # EtfNotFoundException…
└── resource/               # RessourcePedagogique + Media, même découpage
```

- Ne créer un sous-package que lorsqu'il a un premier fichier (pas de dossiers vides).
- Flux unique : `Controller → Service → Repository`. Aucun saut de couche.
- Un domaine n'accède jamais au repository d'un autre domaine : il passe par le **service** de ce domaine.
- `common/` ne contient que du code réellement transverse, jamais de logique propre à un domaine.
- Chaque couche manipule son propre type d'objet ; les conversions passent par les mappers :

  ```
  Client HTTP ◀─ DTO ─▶ Controller ◀─ objet métier ─▶ Service ◀─ entité ─▶ Repository
  ```
  - le **controller** convertit DTO ⇄ objet métier ;
  - le **service** convertit objet métier ⇄ entité (et DTO d'API externe → objet métier).

## Nommage

| Type | Suffixe | Exemple |
|---|---|---|
| Objet métier | aucun | `Etf`, `RessourcePedagogique`, `Media` |
| Entité JPA | `Entity` | `EtfEntity` |
| DTO | `Dto` (précédé de `Request` / `Response` pour l'API Indice) | `EtfResponseDto`, `CreateEtfRequestDto`, `EodhdSymbolDto` |
| Mapper | `Mapper` (fichier de fonctions d'extension) | `EtfMapper.kt` |

## Objets métier (`models/`)

- **Tell, don't ask** : un objet métier porte sa propre logique et protège ses invariants. On lui **demande d'agir** (`etf.refreshedFrom(...)`, `catalog.isStaleAt(now)`) au lieu de lire ses propriétés pour décider à sa place dans le service.
- Classes Kotlin pures : **aucune annotation** Spring, JPA ou Jackson.
- **Immuables** : `data class` en `val` uniquement. Une méthode qui « modifie » l'objet renvoie une nouvelle instance via `copy()`, et son nom le reflète (`refreshedFrom`, `synchronizedWith`).
- `copy()` n'est appelé qu'**à l'intérieur** de l'objet métier : un service ne fait jamais `etf.copy(name = ...)`, il appelle la méthode métier correspondante.
- `copy()` repasse par le constructeur : les invariants du bloc `init` sont donc vérifiés à chaque nouvelle instance.
- Invariants vérifiés à la construction (`init { require(...) }`) : un objet métier invalide ne peut pas exister.
- Les objets métier ne connaissent ni les DTOs ni les entités.
- **Pas de données de paramétrage en dur** dans un objet métier (listes d'ISIN, seuils modifiables…) : elles vont dans `application.yaml`, sont lues par une classe `@ConfigurationProperties` (`<domaine>/config/`), et passées en paramètre par le service (types simples, ou objet métier si une logique le justifie). Les constantes qui définissent une règle métier stable (ex. `TTL`) restent dans l'objet.
- `application.yaml` pour le paramétrage versionné ; `.env` / variables d'environnement uniquement pour les secrets et ce qui varie selon l'environnement.

## Controllers

- **Aucune logique métier.** Un controller : reçoit la requête, valide l'entrée (`@Valid`), convertit le DTO en objet métier si besoin, délègue à **un** service, puis convertit l'objet métier renvoyé en DTO de réponse via le mapper.
- N'injecte **jamais** un repository.
- Expose uniquement des DTOs : ne reçoit ni ne renvoie **jamais** une entité JPA ou un objet métier dans la requête ou la réponse HTTP.
- Pas de `try/catch` : les erreurs sont gérées par le `@RestControllerAdvice` global.
- Routes REST en kebab-case et au pluriel : `/etfs`, `/etfs/{isin}`, `/etfs/compare?isins=...`, `/resources`.

### Pagination

- **Tout endpoint de listing de l'API Indice est paginé**, sans exception, même si la collection est petite aujourd'hui.
- Paramètres de requête : `page` (numéro de page, commence à `0`), `size` (taille, `20` par défaut, `100` au maximum) et, si le tri est proposé, `sort` (ex. `sort=name,asc`). Le controller les reçoit sous forme de `Pageable` (`@PageableDefault(size = 20)`), et la taille maximale est fixée par configuration (`spring.data.web.pageable.max-page-size: 100`).
- Le `Pageable` est transmis au service puis au repository : la pagination se fait **en base** (`LIMIT` / `OFFSET`), jamais en mémoire après un `findAll()`.
- Le service renvoie un `Page<ObjetMétier>`. Le controller le convertit en `PageResponseDto<T>` (`common/dtos/responses/`) avec le mapper générique `page.toDto { it.toDto() }` (`common/mappers/PageMapper.kt`) :

  ```json
  { "content": [ … ], "page": 0, "size": 20, "totalElements": 134, "totalPages": 7 }
  ```
- Ne jamais renvoyer directement un `Page` de Spring Data en JSON : son format n'est pas stable d'une version à l'autre.
- Les métadonnées propres à une réponse (ex. `stale`) vont dans un DTO dédié qui **contient** le `PageResponseDto`, sans le dupliquer : `{ "etfs": { "content": [...], "page": 0, ... }, "fetchedAt": "...", "stale": false }`.
- Un tri par défaut est toujours défini (`@PageableDefault(sort = [...])`), pour que l'ordre des pages soit stable.
- Un tri sur un champ inconnu (`sort=foo`) renvoie 400 (`error.pagination.invalid-sort`), via `ExceptionController`.

## DTOs

- `data class` immuables (`val`), suffixées `Dto`.
- Rangées selon leur rôle HTTP :
  - `dtos/requests/` : corps des **requêtes**, c'est-à-dire ce que l'API Indice reçoit (ou envoie à une API externe) ;
  - `dtos/responses/` : corps des **réponses**, c'est-à-dire ce que l'API Indice renvoie (ou reçoit d'une API externe, ex. `EodhdSymbolDto`).
- Aucune logique : ce sont de simples structures de transport (API Indice ou API externe).
- Validation des entrées avec Jakarta Validation (`@field:NotBlank`, `@field:Size`…). *Nécessite `spring-boot-starter-validation`, à ajouter au premier besoin.*

## Mappers

- Fonctions d'extension simples dans `mappers/XxxMapper.kt`, une par direction. Pas de librairie de mapping.
  - `fun EtfEntity.toModel(): Etf` / `fun Etf.toEntity(): EtfEntity`
  - `fun Etf.toDto(): EtfResponseDto` / `fun CreateEtfRequestDto.toModel(): Etf`
- **Jamais de conversion directe entre DTO et entité** : on passe toujours par l'objet métier.
- Aucune logique métier dans un mapper : il recopie des champs, rien de plus.

## Services

- **Orchestrent** les cas d'usage sans porter la logique propre à un objet : charger les entités, les convertir en objets métier, leur demander d'agir, convertir le résultat en entités pour la persistance.
- La logique qui concerne plusieurs objets ou des dépendances externes (repositories, clients HTTP, `Clock`…) reste dans le service ; celle qui ne concerne qu'un objet va dans cet objet.
- Méthodes publiques : reçoivent et renvoient des **objets métier** (ou des types simples), **jamais de DTO** de l'API Indice. Les entités ne sortent pas du service.
- `@Transactional(readOnly = true)` sur les lectures, `@Transactional` sur les écritures.
- Lèvent des exceptions métier explicites (`EtfNotFoundException`…) : voir la section Exceptions.
- Classe concrète par défaut ; interface seulement si justifiée (cf. YAGNI).

## Exceptions

- **Exceptions métier** : une classe par erreur, dans `<domaine>/exceptions/`, qui hérite de `common/exceptions/BusinessException`. Elle fixe son **statut HTTP** et une **clé de message** par défaut dans son `companion object` :

  ```kotlin
  class EtfNotFoundException(
      message: String = DEFAULT_MESSAGE,
  ) : BusinessException(message, DEFAULT_STATUS) {

      companion object {
          private const val DEFAULT_MESSAGE = "error.etfs.etf-not-found"
          val DEFAULT_STATUS = HttpStatus.NOT_FOUND
      }
  }
  ```
- **Clés de message** au format `error.<domaine>.<erreur-en-kebab-case>` (ex. `error.etfs.etf-not-found`), et non des phrases : c'est l'application mobile qui les traduit pour l'affichage. Même règle pour les messages de validation (`@field:NotBlank(message = "error.etfs.isin-required")`).
- Nommage : `<Notion><Problème>Exception` (`EtfNotFoundException`, `EtfAlreadyExistsException`, `InvalidIsinException`).
- **`ExceptionController`** (`common/controllers/`, `@RestControllerAdvice`) est le seul endroit qui traduit les exceptions en réponses HTTP. Le corps est toujours une **liste** d'`ErrorResponseDto(error, message)` :
  - `MethodArgumentNotValidException` → 400, une entrée par erreur de validation ;
  - `PropertyReferenceException` (tri sur un champ inconnu) → 400 avec la clé `error.pagination.invalid-sort`, sans exposer le nom de l'entité ;
  - `BusinessException` → statut et clé portés par l'exception ;
  - toute autre exception → 500 avec la clé `error.unexpected`, journalisée en `error`. Aucun détail technique (message SQL, URL, trace) n'est renvoyé au client.
- Les **exceptions techniques** qu'un service sait gérer (ex. `EodhdDataUnavailableException`) héritent de `RuntimeException`, pas de `BusinessException` : elles sont interceptées dans le service et n'atteignent jamais le controller.
- Pas de `try/catch` dans les controllers, ni de `ResponseEntity` d'erreur construite à la main ailleurs que dans `ExceptionController`.
- Chaque nouveau handler de `ExceptionController` est couvert par un test unitaire (`ExceptionControllerTest`).

## Entités & base de données

- Entités JPA en `class` (pas `data class`), `equals`/`hashCode` basés sur l'identifiant.
- Simple reflet de la table : **aucune logique métier**. Nom de table explicite avec `@Table(name = "...")`, puisque le suffixe `Entity` fausserait le nom par défaut.
- Valeurs fermées en `enum` stockées en `@Enumerated(EnumType.STRING)` (ex. `MediaType { IMAGE, VIDEO }`).
- Montants et pourcentages financiers en `BigDecimal`, jamais `Double`.
- Schéma géré **uniquement par Flyway** (`ddl-auto: validate`) : voir la section suivante.

## Migrations Flyway (sécurité)

Une migration s'exécute sur des données réelles et ne peut pas être annulée simplement : chaque script est écrit avec les précautions suivantes.

### Fichiers
- Emplacement et nommage : `src/main/resources/db/migration/V<n>__<description>.sql` (ex. `V1__create_etf_table.sql`), numéros croissants sans trou.
- **Ne jamais modifier, renommer ni supprimer une migration déjà appliquée** (Flyway la refuserait, car son checksum changerait) : créer une nouvelle migration.
- Une migration = un changement cohérent et petit.
- Aucun secret ni donnée personnelle dans un script.

### Scripts défensifs
- Toujours rendre le DDL idempotent : `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`, `DROP ... IF EXISTS`.
- PostgreSQL n'accepte pas `IF NOT EXISTS` sur `ADD CONSTRAINT` : faire `DROP CONSTRAINT IF EXISTS` puis `ADD CONSTRAINT`, ou utiliser un bloc `DO $$ ... $$` qui vérifie `pg_constraint`.
- Les mises à jour de données (`UPDATE`, `DELETE`) ont **toujours** une clause `WHERE` et peuvent être rejouées sans effet de bord.
- Ajouter une colonne `NOT NULL` à une table existante : avec un `DEFAULT`, ou en trois étapes (ajout nullable, remplissage, puis `SET NOT NULL`).
- Ne pas utiliser `CREATE INDEX CONCURRENTLY` : il ne peut pas s'exécuter dans la transaction d'une migration.

### Opérations destructrices
- `DROP TABLE`, `DROP COLUMN`, `TRUNCATE`, `DELETE` en masse, changement de type qui réduit une colonne, renommage : **interdits sans validation explicite de l'utilisateur**, après avoir annoncé les données perdues.
- Préférer une évolution en deux temps : ajouter la nouvelle structure et migrer les données, puis supprimer l'ancienne dans une migration ultérieure.

### Configuration et exécution
- Ne jamais activer `flyway clean` (`spring.flyway.clean-disabled` reste à `true`).
- Si `baseline-on-migrate` est activé, `baseline-version` doit être **inférieure à la première migration** (ex. `0`). Sinon, sur une base non vide sans historique, Flyway considère la V1 comme déjà appliquée et ne l'exécute jamais.
- Ne jamais modifier à la main la table `flyway_schema_history`, ni lancer une migration sur une autre base que la base Docker locale.
- Toute remise à zéro de la base locale (suppression de tables, `docker compose down -v`) est **annoncée et validée par l'utilisateur** avant exécution.
- Vérifier chaque nouvelle migration sur la base locale (`SPRING_PROFILES_ACTIVE=local ./mvnw test`) : Flyway doit l'appliquer, et Hibernate doit valider le schéma au démarrage.

## Kotlin

- `val` par défaut, null-safety stricte, **pas de `!!`**.
- Injection par constructeur, pas de `@Autowired` sur champ.
- Préférer les fonctions de collection idiomatiques (`map`, `filter`, `associateBy`…) aux boucles impératives.
- `operator fun invoke` est permis lorsqu'il rend le code plus compact **sans perte de sens**, par exemple pour une fabrique dans un `companion object` qui construit un objet à partir d'autres données, en plus du constructeur.
- Ne pas l'utiliser sur les services, ni lorsque le nom de la méthode porte une information utile : `eodhdClient.fetchEtfs(exchange)` est plus clair que `eodhdClient(exchange)`.

## Tests

- **Objets métier (prioritaires)** : tests unitaires purs, sans mock ni contexte Spring. Chaque méthode métier et chaque invariant sont testés.
- **Services** : tests unitaires sans contexte Spring, dépendances mockées avec **MockK**.
- **Mappers** : un test d'aller-retour lorsque le mapping n'est pas trivial.
- **Controllers** : `@WebMvcTest` + service mocké — vérifier statut HTTP, JSON et validation.
- **Repositories** : `@DataJpaTest` uniquement pour les requêtes custom.
- Arborescence miroir de `src/main` (ex. `etf/services/EtfServiceTest.kt`), classe `XxxTest`.
- Nommage descriptif avec backticks : ``fun `should throw EtfNotFoundException when isin is unknown`()``.
- Structure **Given / When / Then**, un comportement par test, cas nominal **et** cas limites/erreurs.

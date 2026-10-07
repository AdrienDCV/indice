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
│   └── exceptions/         # exceptions de base, @RestControllerAdvice, ErrorResponse
├── etf/
│   ├── controllers/        # EtfController, EtfComparisonController…
│   ├── services/           # EtfService, EtfComparisonService…
│   ├── repositories/       # EtfRepository, EtfPerformanceRepository…
│   ├── entities/           # Etf, EtfPerformance… (entités JPA)
│   ├── dtos/               # EtfResponse, EtfSummaryResponse, EtfComparisonResponse…
│   ├── mappers/            # EtfMapper.kt (fonctions d'extension entité -> DTO)
│   └── exceptions/         # EtfNotFoundException…
└── resource/               # RessourcePedagogique + Media, même découpage
```

- Ne créer un sous-package que lorsqu'il a un premier fichier (pas de dossiers vides).
- Flux unique : `Controller → Service → Repository`. Aucun saut de couche.
- Un domaine n'accède jamais au repository d'un autre domaine : il passe par le **service** de ce domaine.
- `common/` ne contient que du code réellement transverse, jamais de logique propre à un domaine.

## Controllers

- **Aucune logique métier.** Un controller : reçoit la requête, valide l'entrée (`@Valid`), délègue à **un** service, renvoie la réponse.
- N'injecte **jamais** un repository.
- Ne reçoit ni ne renvoie **jamais** une entité JPA : uniquement des DTOs.
- Pas de `try/catch` : les erreurs sont gérées par le `@RestControllerAdvice` global.
- Routes REST en kebab-case et au pluriel : `/etfs`, `/etfs/{isin}`, `/etfs/compare?isins=...`, `/resources`.

## DTOs

- `data class` immuables (`val`), suffixées `Request` / `Response`.
- Les entités ne sortent pas de la couche service : la conversion se fait dans le service via le mapper.
- Mapping par fonctions d'extension simples (`fun Etf.toResponse() = EtfResponse(...)`) dans `mappers/XxxMapper.kt`. Pas de librairie de mapping.
- Validation des entrées avec Jakarta Validation (`@field:NotBlank`, `@field:Size`…). *Nécessite `spring-boot-starter-validation`, à ajouter au premier besoin.*

## Services

- Portent **toute** la logique métier (calculs d'indicateurs, comparaisons, détermination du type de `Media`…).
- `@Transactional(readOnly = true)` sur les lectures, `@Transactional` sur les écritures.
- Lèvent des exceptions métier explicites (`EtfNotFoundException`…) traduites en HTTP par l'advice (404, 400…), avec un corps d'erreur uniforme.
- Classe concrète par défaut ; interface seulement si justifiée (cf. YAGNI).

## Entités & base de données

- Entités JPA en `class` (pas `data class`), `equals`/`hashCode` basés sur l'identifiant.
- Valeurs fermées en `enum` stockées en `@Enumerated(EnumType.STRING)` (ex. `MediaType { IMAGE, VIDEO }`).
- Montants et pourcentages financiers en `BigDecimal`, jamais `Double`.
- Schéma géré **uniquement par Flyway** (`ddl-auto: validate`) : `src/main/resources/db/migration/V<n>__<description>.sql` (ex. `V1__create_etf_table.sql`).
- **Ne jamais modifier une migration déjà appliquée** : en créer une nouvelle.

## Kotlin

- `val` par défaut, null-safety stricte, **pas de `!!`**.
- Injection par constructeur, pas de `@Autowired` sur champ.
- Préférer les fonctions de collection idiomatiques (`map`, `filter`, `associateBy`…) aux boucles impératives.

## Tests

- **Unitaires (prioritaires)** : services et logique métier pure, sans contexte Spring, dépendances mockées avec **MockK** *(à ajouter en scope `test` au premier besoin)*.
- **Controllers** : `@WebMvcTest` + service mocké — vérifier statut HTTP, JSON et validation.
- **Repositories** : `@DataJpaTest` uniquement pour les requêtes custom.
- Arborescence miroir de `src/main` (ex. `etf/services/EtfServiceTest.kt`), classe `XxxTest`.
- Nommage descriptif avec backticks : ``fun `should throw EtfNotFoundException when isin is unknown`()``.
- Structure **Given / When / Then**, un comportement par test, cas nominal **et** cas limites/erreurs.

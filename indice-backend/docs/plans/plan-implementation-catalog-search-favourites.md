# Plan d'implémentation : catalogue complet, recherche et favoris (`GET /etfs`)

> Les conventions du projet sont définies dans le `CLAUDE.md`, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Premier des deux plans de la fonctionnalité « recherche et favoris » : backend (ce plan), puis mobile (`indice_mobile/docs/plans/plan-implementation-catalog-search-favourites.md`).

## Avant de coder

1. **Lis le code existant** du domaine `etf` : `EtfController`, `EtfService`, `EtfDetailService`, `EtfCatalog`, `EtfCatalogProperties`, `EtfRepository`, `EtfEntity`, `EtfMapper`, `EtfDetailMapper`, et les migrations `V1` à `V3`.
2. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.
3. **Économise le quota Twelve Data** : aucun appel réel dans les tests. La vérification manuelle (section 11) déclenche une synchronisation du catalogue, soit un appel.

---

## 1. Objectif

- Proposer **tous les ETF américains** renvoyés par Twelve Data, et non plus une liste de 10 tickers choisis à la main.
- Permettre de **chercher** un ETF par ticker ou par nom.
- Permettre d'**épingler un ETF en favori**, de le retirer, et de n'afficher que les favoris.

## 2. Hors périmètre

- L'authentification : l'application est considérée comme ayant **un seul utilisateur** (ADR 0002, section 9).
- D'autres filtres (niveau de risque, fraîcheur des données…) : ils demanderaient de connaître à l'avance les cours de chaque ETF, donc une tâche planifiée.
- L'exclusion des ETF à effet de levier ou inverses : aucune donnée fiable ne permet de les repérer. Le mobile affiche un rappel général.
- Le tri des résultats par pertinence (ticker exact en tête) : le tri par défaut reste le nom.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Catalogue | Tous les ETF renvoyés par `GET /etfs?country=United States` de Twelve Data. Suppression de `etf.catalog.selected-tickers` ; `country` est conservé |
| Recherche | Paramètre `search` : le **ticker commence par** le texte, **ou** le **nom contient** le texte, sans tenir compte des majuscules ni des espaces au début et à la fin. Texte vide ou absent : pas de filtre |
| Filtre favoris | Paramètre `favourites=true` : seulement les ETF épinglés. Combinable avec `search` |
| Pagination | En base, comme aujourd'hui (`page`, `size` 20 par défaut et 100 au maximum, `sort=name` par défaut) |
| Stockage des favoris | Table `favourite_etf (ticker)`, une seule colonne, clé primaire et clé étrangère vers `etf (ticker)` en `ON DELETE CASCADE` : un ETF retiré du catalogue perd son favori |
| Utilisateur | Un seul : les favoris ne sont rattachés à personne. Une authentification devra ajouter une colonne utilisateur (ADR 0002) |
| Épingler | `PUT /etfs/{ticker}/favourite` : **201** si l'ETF n'était pas en favori, **200** s'il l'était déjà (idempotent), sans corps |
| Retirer | `DELETE /etfs/{ticker}/favourite` : **204** dans tous les cas, même si l'ETF n'était pas en favori ou est inconnu (idempotent) |
| Erreurs | Ticker mal formé : 400 `error.etfs.invalid-ticker` ; ticker absent du catalogue à l'ajout : 404 `error.etfs.etf-not-found` (exceptions existantes) |
| État favori | Champ `favourite` dans chaque ETF de `GET /etfs` et dans `GET /etfs/{ticker}` |

## 4. Contrat d'API

**Ajouts, sans changement cassant** : nouveaux paramètres facultatifs, nouveau champ `favourite`, deux nouveaux endpoints. Le mobile actuel continue de fonctionner (il ignore le champ inconnu).

### 4.1 `GET /api/etfs?search=van&favourites=true&page=0&size=50`

```json
{
  "etfs": {
    "content": [
      { "ticker": "VGK", "exchange": "NYSE ARCA", "name": "Vanguard FTSE Europe ETF", "currency": "USD", "favourite": true }
    ],
    "page": 0, "size": 50, "totalElements": 1, "totalPages": 1
  },
  "fetchedAt": "2026-11-01T08:00:00Z",
  "stale": false
}
```

### 4.2 `GET /api/etfs/{ticker}`

Réponse actuelle, avec en plus `"favourite": true | false` au premier niveau, à côté de `stale`.

### 4.3 `PUT` et `DELETE /api/etfs/{ticker}/favourite`

| Requête | Cas | Statut |
|---|---|---|
| `PUT` | L'ETF n'était pas en favori | 201, sans corps |
| `PUT` | L'ETF était déjà en favori | 200, sans corps |
| `DELETE` | Tous les cas | 204 |
| Les deux | Ticker mal formé | 400 `error.etfs.invalid-ticker` |
| `PUT` | Ticker absent du catalogue | 404 `error.etfs.etf-not-found` |

PUT plutôt que POST : PUT est idempotent (*« calling it once is no different from calling it several times successively »*, [MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods/PUT)), ce qui correspond à « épingler » : épingler deux fois revient à épingler une fois. Les codes 201 et 200 suivent la même page : 201 quand la ressource est créée, 200 ou 204 quand elle existait déjà.

## 5. Catalogue complet

- `EtfCatalogProperties` : suppression de `selectedTickers`.
- `application.yaml` : suppression de `selected-tickers` et de ses commentaires ; le commentaire de `country` explique que le catalogue contient tous les ETF de ce pays renvoyés par Twelve Data.
- `EtfService.fetchSource` : plus de filtre sur les tickers ; le message d'avertissement devient « aucun ETF dans la réponse de Twelve Data ».
- `EtfCatalog.synchronizedWith(source)` : plus de paramètre `selectedTickers` ; le dédoublonnage par ticker (`distinctBy`) est conservé, au cas où un ticker serait renvoyé pour plusieurs places de cotation.

## 6. Recherche et filtre favoris

### 6.1 Controller (`EtfController`)

```kotlin
@GetMapping("/etfs")
fun retrieveEtfs(
    @RequestParam search: String?,
    @RequestParam(defaultValue = "false") favourites: Boolean,
    @PageableDefault(size = 20, sort = ["name"]) pageable: Pageable,
): EtfCatalogResponseDto
```

### 6.2 Service (`EtfService.retrieveEtfs(pageable, search, favouritesOnly)`)

- La synchronisation avec Twelve Data ne change pas.
- La recherche est normalisée (`search?.trim()?.lowercase().orEmpty()`), puis transmise au repository avec `favouritesOnly`.
- Une fois la page chargée, `favouriteEtfRepository.findAllById(tickers de la page)` indique en une requête quels ETF sont en favori ; chaque entité est convertie avec `toModel(favourite = …)`.

### 6.3 Requête (`EtfRepository`)

```kotlin
@Query("""
    select e from EtfEntity e
    where (lower(e.ticker) like concat(:search, '%') or lower(e.name) like concat('%', :search, '%'))
      and (:favouritesOnly = false or exists (select f from FavouriteEtfEntity f where f.ticker = e.ticker))
""")
fun findInCatalog(search: String, favouritesOnly: Boolean, pageable: Pageable): Page<EtfEntity>
```

- Un texte vide donne `like '%'`, qui garde tout. Pas de `:search is null` : PostgreSQL ne sait pas toujours typer un paramètre `null` dans un `lower(...)`.
- Les caractères `%` et `_` saisis ne sont pas échappés : ils élargissent seulement la recherche (lecture seule, sans risque).
- Le tri du `Pageable` s'applique à cette requête ; un tri inconnu reste traduit en 400 par `ExceptionController`.

## 7. Favoris

### 7.1 Migration `V4__create_favourite_etf_table.sql`

```sql
CREATE TABLE IF NOT EXISTS favourite_etf (
    ticker VARCHAR(20) PRIMARY KEY REFERENCES etf (ticker) ON DELETE CASCADE
);
```

`VARCHAR(20)` comme `etf.ticker`. La contrainte `etf_ticker_key` (V2) rend la clé étrangère possible. Aucune donnée existante n'est touchée.

### 7.2 Entité et repository

- `FavouriteEtfEntity` (`@Table(name = "favourite_etf")`) : un seul champ, `@Id val ticker: String`, `equals`/`hashCode` sur le ticker.
- `FavouriteEtfRepository : JpaRepository<FavouriteEtfEntity, String>` : uniquement les méthodes fournies par Spring Data (`existsById`, `save`, `deleteById`, `findAllById`).

### 7.3 Objet métier et DTOs

- `Etf` : `val favourite: Boolean = false`. Un ETF venu de Twelve Data vaut `false` ; la valeur réelle est renseignée par le service à la lecture.
- `EtfMapper` : `EtfEntity.toModel(favourite: Boolean = false)`.
- `EtfResponseDto` et `EtfDetailResponseDto` reçoivent `favourite`, lu dans `Etf` (le détail le prend dans `EtfDetail.etf`).
- `EtfDetailService` : `favouriteEtfRepository.existsById(ticker)` pour construire l'`Etf` de la fiche.

### 7.4 Service et controller

- `EtfService`, en `@Transactional` :
  - `addFavourite(ticker): Boolean` : normalise le ticker (`Etf.normalizeTicker`, 400 si mal formé), vérifie que l'ETF existe (`findByTicker`, sinon `EtfNotFoundException`, 404), puis `existsById` et `save` s'il est absent. Renvoie vrai si l'ETF vient d'être épinglé ;
  - `removeFavourite(ticker)` : normalise le ticker, puis `deleteById`. Pas de vérification d'existence : retirer un favori absent répond 204, comme le veut l'idempotence.
- `EtfController` :

```kotlin
@PutMapping("/etfs/{ticker}/favourite")
fun addFavourite(@PathVariable ticker: String): ResponseEntity<Unit> =
    if (etfService.addFavourite(ticker)) ResponseEntity.status(HttpStatus.CREATED).build() else ResponseEntity.ok().build()

@DeleteMapping("/etfs/{ticker}/favourite")
@ResponseStatus(HttpStatus.NO_CONTENT)
fun removeFavourite(@PathVariable ticker: String) = etfService.removeFavourite(ticker)
```

## 8. Tests

| Classe | Contenu |
|---|---|
| `EtfCatalogTest` | Adapté : tous les ETF de la source sont gardés, dédoublonnés par ticker |
| `EtfServiceTest` | Adapté (plus de liste choisie) ; recherche normalisée et transmise avec le filtre favoris ; `favourite` de chaque ETF de la page ; `addFavourite` (nouveau → vrai, existant → faux sans nouvel enregistrement) ; `removeFavourite` ; ticker mal formé → `InvalidTickerException` ; ticker inconnu à l'ajout → `EtfNotFoundException` |
| `EtfDetailServiceTest` | `favourite` vrai ou faux |
| `EtfRepositoryTest` (`@DataJpaTest`, requête custom) | Recherche par début de ticker, par morceau de nom, sans tenir compte des majuscules ; filtre favoris ; recherche et favoris combinés ; texte vide → tout ; favori supprimé avec son ETF (cascade) |
| `EtfControllerTest` | Paramètres `search` et `favourites` transmis ; `favourite` dans le JSON du catalogue et du détail ; PUT → 201 puis 200 ; DELETE → 204 ; 400 et 404 |
| `EtfMapperTest`, `EtfDetailMapperTest` | Champ `favourite` |

`./mvnw clean test` avec la base Docker démarrée : Flyway applique V4 et Hibernate valide le schéma.

## 9. ADR

Création de `docs/adr/` dans le backend, sur le modèle du mobile : `README.md` (rôle, cycle de vie, organisation, index) et `0000-template.md`.

- **ADR-0001 — Catalogue complet des ETF américains** : passage d'une liste choisie au catalogue complet de Twelve Data. Alternatives : liste choisie agrandie dans `application.yaml`. Conséquences : pagination et recherche indispensables côté mobile, favoris filtrés par le backend, ETF à effet de levier ou inverses présents (rappel côté mobile).
- **ADR-0002 — Favoris stockés côté backend, application à utilisateur unique** : table `favourite_etf (ticker)` sans propriétaire, faute d'authentification (non exigée par le sujet). Alternatives : favoris sur le téléphone (Shared Preferences) filtrés par `?tickers=`, identifiant d'appareil anonyme. Conséquences : favoris communs à tous les appareils connectés au même backend ; modifier un favori demande le réseau ; une authentification ajoutera une colonne utilisateur à `favourite_etf`.

## 10. Documentation

- **Glossaire** : suppression de « ETF sélectionnés » ; mise à jour de « Catalogue d'ETF » (tous les ETF américains de Twelve Data) ; ajout de « Favori » (`favourite`, `FavouriteEtfEntity`, table `favourite_etf`) et « Recherche dans le catalogue » (paramètre `search`).
- `CLAUDE.md` backend : rien à changer.

## 11. Vérification manuelle

Port 8080 libre, profil `local` :

1. `curl "http://localhost:8080/api/etfs?size=5"` : la première synchronisation récupère tout le catalogue (un appel Twelve Data). **Noter** le nombre d'ETF (`totalElements`) et la durée de cette première réponse.
2. `curl "http://localhost:8080/api/etfs?search=vanguard&size=5"` puis `?search=sp`.
3. `curl -i -X PUT http://localhost:8080/api/etfs/SPY/favourite` (201), une seconde fois (200), puis `curl "http://localhost:8080/api/etfs?favourites=true"`.
4. `curl -i -X DELETE http://localhost:8080/api/etfs/SPY/favourite` (204).

## 12. Points de vigilance

- **Durée de la première synchronisation** : `saveAll` sur des milliers d'ETF à identifiant déjà renseigné fait une lecture par ETF avant l'insertion. Si la durée mesurée en 11.1 est gênante, l'optimisation (insertion par lots) fera l'objet d'une décision séparée.
- **Formats du catalogue complet** : `etf.exchange` est en `VARCHAR(10)` et le ticker doit respecter `^[A-Z0-9.-]{1,10}$` pour la fiche. Vérifier après la première synchronisation qu'aucun ETF n'est refusé (erreur d'insertion ou fiche en 400).
- **Quota** : la synchronisation reste un appel par semaine ; chaque fiche ouverte pour la première fois de la journée coûte un appel (8 par minute au plus).

## 13. Découpage en commits

Branche `feat/backend/catalog-search-favourites`, depuis `main` :

- `✨ : backend - search the full etf catalog and pin favourites`

## 14. Critères de fin

- [ ] `./mvnw clean test` passe (base Docker démarrée), V4 appliquée.
- [ ] Vérification manuelle de la section 11 faite, nombre d'ETF et durée de la première synchronisation notés dans la PR.
- [ ] Aucune donnée de liste de tickers ne subsiste (`application.yaml`, propriétés, tests, glossaire).
- [ ] ADR 0001 et 0002 écrites, index à jour.

---

## 15. Ajustements pendant le développement

| Sujet | Plan | Code livré | Raison |
|---|---|---|---|
| `CLAUDE.md` backend | Rien à changer | Une phrase renvoie vers `docs/adr/README.md`, à côté du glossaire et des plans | Premier dossier d'ADR du backend : sans ce renvoi, il passerait inaperçu |
| ETF à effet de levier ou inverses | Hors périmètre (pas de donnée fiable) | `Etf.isLeveragedOrInverse()` (règle stricte sur le nom), champ `leveragedOrInverse` dans le catalogue et la fiche. ADR-0003 | Demande après les essais : le rappel général ne permet pas de reconnaître ces ETF. Règle mesurée sur le catalogue local : 782 ETF repérés sur 11 422, échantillon de 30 entièrement correct |

# Plan d'implémentation : ressources pédagogiques (`GET /resources`)

> Les conventions du projet sont définies dans le `CLAUDE.md`, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Premier des deux plans de la fonctionnalité « ressources pédagogiques » : backend (ce plan), puis mobile (`indice_mobile/docs/plans/plan-implementation-resources.md`).

## Avant de coder

1. **Lis le code existant** du domaine `etf` (controller, services, favoris, mappers, tests) : le domaine `resource` suit le même découpage.
2. **Lis les fausses données du mobile** (`indice_mobile/lib/data/fake_resources.dart`) : elles servent de données de départ (section 6.3).

---

## 1. Objectif

Le module Apprendre du mobile affiche des ressources factices codées en dur. Elles doivent être **stockées en base** et exposées par l'API : liste paginée et filtrée, fiche complète, favoris.

## 2. Hors périmètre

- La création, la modification et la suppression de ressources (back-office) : les ressources sont insérées par migration.
- L'hébergement des médias : la base ne stocke que leur URL.
- L'authentification : favoris sans utilisateur, comme pour les ETF (ADR 0002).

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Liste et fiche | La liste ne renvoie pas `content` (articles longs) ; la fiche `GET /resources/{id}` le renvoie |
| Identifiant | `UUID` |
| Type | `type` : `VIDEO` ou `ARTICLE`, nature du contenu |
| Média | Facultatif. Objet `{ url, type }`, `type` (`IMAGE` ou `VIDEO`) **déduit de l'extension** de l'URL (glossaire). Seule l'URL est stockée |
| Invariant | Une ressource `VIDEO` a un média de type `VIDEO` |
| Durée | `durationMinutes`, entier strictement positif. La mise en forme (« 5 min ») est faite par le mobile |
| Niveau | `level` : `BEGINNER`, `INTERMEDIATE`, `EXPERIENCED`, `PROFESSIONAL`. Libellé français côté mobile |
| Recherche | `search` : le titre **ou** la description contient le texte, sans tenir compte des majuscules ni des espaces autour. Vide ou absent : pas de filtre |
| Filtre niveaux | `levels=BEGINNER,INTERMEDIATE` : ressources d'un des niveaux. Absent : tous |
| Filtre favoris | `favourites=true`, combinable avec les autres filtres |
| Pagination | `page`, `size` (20 par défaut, 100 au maximum), tri par défaut `title` |
| Favoris | Table `favourite_resource (resource_id)`, `PUT` / `DELETE /resources/{id}/favourite`, même comportement que les ETF |

## 4. Contrat d'API

**Ajouts uniquement**, aucun changement cassant.

### 4.1 `GET /api/resources?search=frais&levels=BEGINNER&favourites=false&page=0&size=20`

```json
{
  "content": [
    {
      "id": "6c1f…",
      "title": "Comprendre les frais",
      "description": "Les différents frais d'un ETF et leur impact dans le temps.",
      "type": "ARTICLE",
      "durationMinutes": 8,
      "level": "BEGINNER",
      "media": null,
      "favourite": false
    }
  ],
  "page": 0, "size": 20, "totalElements": 1, "totalPages": 1
}
```

`media`, quand il est présent : `{ "url": "https://…/butterfly.mp4", "type": "VIDEO" }`.

### 4.2 `GET /api/resources/{id}`

Mêmes champs qu'un élément de la liste, plus `"content": "…"`.

### 4.3 Favoris

| Requête | Cas | Réponse |
|---|---|---|
| `PUT /resources/{id}/favourite` | Ressource existante | 200, fiche (4.2) avec `favourite: true` |
| `PUT` | Ressource inconnue | 404 `error.resources.resource-not-found` |
| `DELETE /resources/{id}/favourite` | Tous les cas | 204 |

### 4.4 Erreurs

| Cas | Réponse |
|---|---|
| Ressource inconnue (fiche, `PUT`) | 404 `error.resources.resource-not-found` |
| Identifiant qui n'est pas un UUID, niveau inconnu dans `levels` | 400 `error.request.invalid-parameter` (nouveau handler, section 7) |
| Tri inconnu | 400 `error.pagination.invalid-sort` (existant) |

## 5. Objets métier (`resource/models/`)

- `ResourceType { VIDEO, ARTICLE }`, `ResourceLevel { BEGINNER, INTERMEDIATE, EXPERIENCED, PROFESSIONAL }`, `MediaType { IMAGE, VIDEO }`.
- `Media(url)` : `type` calculé depuis l'extension du chemin de l'URL (sans paramètres de requête, sans tenir compte des majuscules). `jpg`, `jpeg`, `png`, `webp`, `gif` → `IMAGE` ; `mp4`, `mov`, `webm`, `m3u8` → `VIDEO`. URL vide ou extension inconnue : refusée à la construction.
- `RessourcePedagogique(id, title, description, content, type, durationMinutes, level, media, favourite = false)` : titre non vide, durée > 0, ressource `VIDEO` avec média vidéo.

## 6. Base de données

### 6.1 `V5__create_resource_table.sql`

```sql
CREATE TABLE IF NOT EXISTS resource (
    id               UUID         PRIMARY KEY,
    title            VARCHAR(255) NOT NULL,
    description      VARCHAR(500) NOT NULL,
    content          TEXT         NOT NULL,
    type             VARCHAR(20)  NOT NULL,
    duration_minutes INTEGER      NOT NULL CHECK (duration_minutes > 0),
    level            VARCHAR(20)  NOT NULL,
    media_url        VARCHAR(2048)
);
```

### 6.2 `V6__create_favourite_resource_table.sql`

```sql
CREATE TABLE IF NOT EXISTS favourite_resource (
    resource_id UUID PRIMARY KEY REFERENCES resource (id) ON DELETE CASCADE
);
```

### 6.3 `V7__insert_initial_resources.sql`

Les 6 ressources de `fake_resources.dart`, avec des UUID fixes et `ON CONFLICT (id) DO NOTHING` (rejouable). Les vidéos sont des vidéos de démonstration publiques sans lien avec les titres : à remplacer par une migration ultérieure.

## 7. Couches

- `ResourceEntity` (`@Table(name = "resource")`, enums en `EnumType.STRING`), `FavouriteResourceEntity`.
- `ResourceRepository.findInCatalog(search, levels, favouritesOnly, pageable)` : requête JPQL comme `EtfRepository.findInCatalog`. Sans niveau choisi, le service passe tous les niveaux, ce qui évite un `in` sur une liste vide.
- `ResourceService` : `retrieveResources`, `retrieveResource`, `addFavourite`, `removeFavourite` ; favoris de la page chargés en une requête (`findAllById`).
- `ResourceController` : 4 endpoints, `@PageableDefault(size = 20, sort = ["title"])`.
- DTOs : `ResourceResponseDto`, `ResourceDetailResponseDto`, `MediaResponseDto`. Mapper `ResourceMapper.kt`.
- `ResourceNotFoundException` (404, `error.resources.resource-not-found`).
- `ExceptionController` : `MethodArgumentTypeMismatchException` → 400 `error.request.invalid-parameter`.

## 8. Tests

| Classe | Contenu |
|---|---|
| `MediaTest` | Type déduit de chaque extension, majuscules, paramètres de requête ; URL vide et extension inconnue refusées |
| `RessourcePedagogiqueTest` | Invariants (titre, durée, vidéo sans média vidéo) |
| `ResourceServiceTest` | Recherche normalisée, filtres transmis, `favourite` de la page, fiche, 404, favoris |
| `ResourceRepositoryTest` | Recherche titre / description, niveaux, favoris, combinaisons, cascade |
| `ResourceControllerTest` | JSON de la liste et de la fiche, paramètres, favoris, 400 et 404 |
| `ResourceMapperTest` | Entité ⇄ objet métier, média absent |
| `ExceptionControllerTest` | Nouveau handler |

## 9. Documentation

- Glossaire : ressource pédagogique (champs, `ResourceLevel`, `ResourceType`), média (extensions reconnues), recherche et filtres des ressources.
- ADR 0002 : les favoris couvrent aussi les ressources (`favourite_resource`).

## 10. Vérification manuelle

1. `curl "http://localhost:8080/api/resources"` : 6 ressources triées par titre.
2. `curl "http://localhost:8080/api/resources?levels=BEGINNER&search=etf"`.
3. `curl "http://localhost:8080/api/resources/{id}"` puis `curl -i -X PUT …/favourite` et `?favourites=true`.

## 11. Découpage en commits

Branche `feat/backend/resources`, depuis `main` :

- `🗃️ : backend - create resource tables with initial resources`
- `✨ : backend - expose pedagogical resources with favourites`

## 12. Critères de fin

- [ ] `./mvnw clean test` passe (base Docker démarrée), V5 à V7 appliquées.
- [ ] Vérification manuelle de la section 10 faite.
- [ ] Glossaire et ADR 0002 à jour.

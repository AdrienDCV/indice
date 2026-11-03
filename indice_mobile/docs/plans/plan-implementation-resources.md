# Plan d'implémentation : ressources pédagogiques depuis l'API (onglet Apprendre)

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Second des deux plans de la fonctionnalité « ressources pédagogiques » : backend (`indice-backend/docs/plans/plan-implementation-resources.md`, à merger avant), puis mobile (ce plan).

## Avant de coder

1. **Lis le code existant** : `lib/pages/learn_page.dart`, `lib/pages/resource_detail_page.dart`, `lib/widgets/resource_card.dart`, `lib/widgets/resource_thumbnail.dart`, `lib/data/fake_resources.dart`, `lib/utils/filter_resources.dart`, et le module Comparer (`lib/screens/compare/`, `lib/stores/etf/`, `lib/repositories/etf_repository.dart`, `test/fakes/`), qui sert de modèle.
2. **Lis le contrat de l'API** : section 4 du plan backend.

---

## 1. Objectif

Remplacer les ressources factices du module Apprendre par celles de l'API : liste paginée avec recherche, filtres de niveau et favoris, fiche complète, étoile de favori.

## 2. Hors périmètre

- Le cache hors ligne des ressources (ADR 0001 : seulement les ETF favoris).
- L'affichage d'un média image dans la fiche : la vignette actuelle est conservée pour les articles.
- La migration des autres fichiers de `lib/pages/` (accueil, construire, navigation).

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Recherche | `AppSearchBar` existant, `GET /resources?search=…` 300 ms après la dernière frappe |
| Filtres | Puces « Favoris » et niveaux existantes, envoyées à l'API (`favourites`, `levels`). Le filtrage local disparaît |
| Pagination | Au défilement, par pages de 20 |
| Étoile | Sur chaque carte et dans la barre du haut de la fiche. Changement immédiat, retour en arrière et message « Impossible de modifier les favoris. » en cas d'échec |
| Cohérence | `ResourceCatalogStore` fourni au niveau de l'app : une étoile changée sur la fiche met à jour la carte |
| Navigation | `/learn/resource/:id` : la fiche charge la ressource par son id (fini l'objet passé en `extra`) |
| Libellés | `Débutant`, `Vidéo`, `5 min`… calculés par des fonctions de `lib/utils/` |

## 4. Contrat de l'API

Voir le plan backend, section 4.

| Appel | Usage mobile |
|---|---|
| `GET /resources?page=0&size=20&search=…&levels=BEGINNER,INTERMEDIATE&favourites=true` | Liste (paramètres vides omis) |
| `GET /resources/{id}` | Fiche |
| `PUT` / `DELETE /resources/{id}/favourite` | Étoile |

## 5. Models (`lib/models/resource/`)

- `ResourceData` : `id`, `title`, `description`, `type` (`ResourceType`), `durationMinutes`, `level` (`ResourceLevel`), `MediaData? media`, `favourite`.
- `ResourceDetailData` : mêmes champs, plus `content`.
- `MediaData` : `url`, `type` (`MediaType`).
- Enums `ResourceType { video, article }`, `ResourceLevel { beginner, intermediate, experienced, professional }`, `MediaType { image, video }` avec `@JsonValue('VIDEO')`…
- La liste utilise `PaginatedData<ResourceData>` (`lib/models/common/`).

## 6. Repository (`lib/repositories/resource_repository.dart`)

```dart
Future<PaginatedData<ResourceData>> retrieveResources({int page = 0, int size = 20, String search = '', Set<ResourceLevel> levels = const {}, bool favouritesOnly = false});
Future<ResourceDetailData> retrieveResource(String id);
Future<ResourceDetailData> addFavourite(String id);   // PUT
Future<void> removeFavourite(String id);              // DELETE
```

Enregistré dans `injection.dart`.

## 7. Stores (`lib/stores/resource/`)

- `ResourceCatalogStore` (fourni dans `IndiceApp`, paresseux) : état `resources`, `search`, `levels`, `favouritesOnly`, `nextPage`, `hasMore`, `isLoading`, `errorKey`, `isLoadingMore`, `loadMoreErrorKey`, `favouriteErrorKey`. Méthodes `init`, `searchChanged` (300 ms), `levelToggled`, `favouritesOnlyChanged`, `loadMore`, `toggleFavourite`, `favouriteChanged`. Réponse obsolète ignorée (compteur de requêtes), comme `EtfCatalogStore`.
- `ResourceDetailStore` (créé par la fiche) : `resource`, `isLoading`, `errorKey`, `favouriteErrorKey` ; `init`, `toggleFavourite`.

## 8. Écrans et widgets

- `lib/screens/learn/learn_screen.dart` remplace `lib/pages/learn_page.dart` : même mise en page, trois cas de l'état (chargement, `ErrorView`, données), chargement de la suite au défilement, états vides (« Aucune ressource ne correspond à ces filtres. », « Aucun favori pour le moment. »).
- `lib/screens/learn/resource_detail_screen.dart` remplace `lib/pages/resource_detail_page.dart` : lecteur vidéo si `media.type` est `video`, vignette sinon ; étoile dans la barre du haut.
- `ResourceCard` et `ResourceThumbnail` déplacés dans `lib/widgets/card/`, et reçoivent des valeurs prêtes à afficher (titre, durée formatée, type, favori) au lieu de l'ancien `Resource`.
- `lib/utils/resource_formatting.dart` : `formatDuration(int minutes)`, `ResourceLevel.label`, `ResourceType.label`.
- `lib/errors/error_messages.dart` : `error.resources.resource-not-found` (« Cette ressource est introuvable. ») et `error.request.invalid-parameter`.

## 9. Suppressions

`lib/data/fake_resources.dart`, `lib/models/resource.dart`, `lib/models/level.dart`, `lib/models/resource_type.dart`, `lib/utils/filter_resources.dart`, `lib/pages/learn_page.dart`, `lib/pages/resource_detail_page.dart`, et leurs tests éventuels.

## 10. Tests

| Fichier | Contenu |
|---|---|
| `test/repositories/resource_repository_test.dart` | Paramètres envoyés et omis ; JSON lu (média absent ou présent) ; `PUT` / `DELETE` ; erreur remontée |
| `test/stores/resource/resource_catalog_store_test.dart` | Page 0, `loadMore`, recherche après 300 ms, niveaux, favoris, réponse obsolète ignorée, `toggleFavourite` (immédiat, annulé en cas d'échec), `favouriteChanged` |
| `test/stores/resource/resource_detail_store_test.dart` | Chargement, erreur, `toggleFavourite` |
| `test/utils/resource_formatting_test.dart` | Durées et libellés |
| `test/fakes/fake_resource_repository.dart` | Faux repository pour les stores |

## 11. Découpage en commits

Branche `feat/mobile/resources`, depuis `main` (backend mergé) :

- `✨ : mobile - load learn resources from the api`
- `🔥 : mobile - remove fake resources`

## 12. Critères de fin

- [ ] `flutter analyze` sans avertissement, `flutter test` vert.
- [ ] Vérification sur le simulateur avec l'API locale : liste, recherche, niveaux, favoris (carte et fiche), lecture d'une vidéo.
- [ ] Plus aucune référence aux fausses données.

---

## 13. Ajustements pendant le développement

| Sujet | Plan | Code livré | Raison |
|---|---|---|---|
| Route de la fiche | `/learn/resource/:id` | `/resource/:id`, au-dessus de la barre de navigation | Comportement actuel conservé : la fiche s'ouvrait déjà en plein écran, depuis l'onglet Apprendre comme depuis l'accueil |
| `addFavourite` | Renvoie `ResourceDetailData` | `Future<void>` | La réponse n'est pas utilisée : le store met l'étoile à jour immédiatement (pas de cache hors ligne pour les ressources) |
| Accueil (`lib/pages/home_page.dart`) | Hors périmètre | Lit `ResourceCatalogStore` pour « Nouveauté pédagogique » | Il affichait les fausses données supprimées. Il montre la même liste que l'onglet Apprendre, filtres compris |
| `ResourceThumbnail` | Déplacé dans `lib/widgets/card/` | Laissé à sa place | Il ne sert pas qu'aux cartes (fiche détail) |
| Fiche détail | — | L'information « En favori / Pas en favori » est remplacée par le bouton marque-page de la barre du haut | Le bouton montre déjà l'état |
| `flutter analyze` | Critère de fin | `dart analyze` | `flutter analyze` plante sur le chemin du projet, qui contient un caractère accentué (`Développement`) ; `dart analyze` fait la même analyse |

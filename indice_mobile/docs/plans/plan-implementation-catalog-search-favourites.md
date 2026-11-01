# Plan d'implémentation : recherche, favoris et catalogue paginé (onglet Comparer)

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Second des deux plans de la fonctionnalité « recherche et favoris » : backend (`indice-backend/docs/plans/plan-implementation-catalog-search-favourites.md`, à merger avant), puis mobile (ce plan).

## Avant de coder

1. **Lis le code existant** : `lib/screens/compare/`, `lib/stores/etf/`, `lib/repositories/etf_repository.dart`, `lib/models/etf/`, `lib/widgets/card/etf_card.dart`, `lib/widgets/app_search_bar.dart`, `lib/widgets/filter_toggle.dart`, `lib/widgets/field/select_field.dart`, `test/fakes/`.
2. **Lis le contrat de l'API** : section 4 du plan backend (`search`, `favourites`, champ `favourite`, `PUT` / `DELETE /etfs/{ticker}/favourite`).
3. **Vérifie l'API de `SearchAnchor`** (Material 3, Flutter du projet) avant d'écrire le sélecteur de la comparaison (section 9). Si elle ne permet pas des suggestions chargées de façon asynchrone, revenir vers l'utilisateur avec une alternative.
4. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.

---

## 1. Objectif

Avec le catalogue complet (plusieurs milliers d'ETF), l'onglet Comparer doit permettre de :
- **parcourir** le catalogue page par page ;
- **chercher** un ETF par ticker ou par nom ;
- **épingler** un ETF en favori (étoile) et n'afficher que les favoris ;
- **choisir** les deux ETF d'une comparaison en les cherchant.

## 2. Hors périmètre

- Le cache hors ligne : la branche `feat/mobile/api-cache` sera reprise après ce plan (section 12).
- D'autres filtres (niveau de risque…), le tri des résultats par pertinence.
- Les favoris des ressources pédagogiques (module Apprendre, données fictives).
- Le style définitif : thème existant.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Favoris | Stockés **côté backend** (application à utilisateur unique, ADR backend 0002). Le mobile ne stocke rien |
| Recherche | Champ en haut du catalogue, `GET /etfs?search=…`, envoyé **300 ms** après la dernière frappe. Champ vide : tout le catalogue |
| Filtre favoris | Puce « Mes favoris » (`FilterToggle`) à côté de la recherche, `GET /etfs?favourites=true`, combinable avec la recherche |
| Pagination | Au défilement, par pages de **50**. Nouvelle recherche ou changement de la puce : retour à la page 0 |
| Étoile | Sur chaque carte et dans la barre du haut de la fiche. Étoile vide → `PUT`, étoile pleine → `DELETE`. Changement **immédiat** à l'écran, retour à l'état précédent et message « Impossible de modifier les favoris. » si l'appel échoue |
| Cohérence | Une étoile changée sur la fiche met à jour la carte du catalogue (`EtfCatalogStore`, fourni au niveau de l'app), sans recharger la liste. Avec la puce active, retirer un favori depuis le catalogue retire sa carte |
| Sélecteurs de la comparaison | Champs avec suggestions (`SearchAnchor`), `GET /etfs?search=…&size=10`. L'ETF choisi de l'autre côté est exclu des suggestions. Ils ne dépendent plus d'`EtfCatalogStore` |
| ETF à effet de levier | Ligne d'information discrète et toujours visible sous la recherche (section 8.3) |

## 4. Contrat de l'API

Voir le plan backend, section 4. Résumé :

| Appel | Usage mobile |
|---|---|
| `GET /etfs?page=0&size=50&search=van&favourites=true` | Catalogue (paramètres `search` et `favourites` omis quand inutiles) |
| `GET /etfs?search=van&size=10` | Suggestions des sélecteurs de la comparaison |
| `PUT /etfs/{ticker}/favourite` | Épingler : 201 ou 200, sans corps |
| `DELETE /etfs/{ticker}/favourite` | Retirer : 204 |

Champ `favourite` (booléen, toujours présent) dans chaque ETF du catalogue et dans la fiche.

## 5. Données (`lib/models/etf/`)

- `EtfData` : `required bool favourite`.
- `EtfDetailData` : `required bool favourite`.

## 6. Repository (`lib/repositories/etf_repository.dart`)

```dart
Future<EtfCatalogData> retrieveEtfs({int page = 0, int size = 50, String search = '', bool favouritesOnly = false});
Future<void> addFavourite(String ticker);      // PUT
Future<void> removeFavourite(String ticker);   // DELETE
```

- `search` vide et `favouritesOnly` faux ne sont pas envoyés.
- Les suggestions de la comparaison réutilisent `retrieveEtfs(search: …, size: 10)`.

## 7. Stores (`lib/stores/etf/`)

### 7.1 `EtfCatalogStore` (fourni au niveau de l'app, existant)

État (`EtfCatalogState`) :

| Champ | Rôle |
|---|---|
| `etfs` (`List<EtfData>`) | ETF accumulés des pages chargées |
| `search` (`String`), `favouritesOnly` (`bool`) | Critères en cours |
| `nextPage` (`int`), `hasMore` (`bool`) | Pagination (`hasMore` : `page + 1 < totalPages`) |
| `fetchedAt`, `stale` | Repris de la première page, pour le bandeau actuel |
| `isLoading`, `errorKey` | Première page : chargement et erreur (écran `ErrorView`) |
| `isLoadingMore`, `loadMoreErrorKey` | Page suivante : chargement et erreur (bas de liste) |

Méthodes :
- `init()` : charge la page 0 avec les critères en cours.
- `searchChanged(String text)` : relance la page 0 **300 ms** après le dernier appel (`Timer`, annulé à chaque frappe et dans `close()`).
- `favouritesOnlyChanged(bool value)` : relance la page 0 immédiatement.
- `loadMore()` : charge la page suivante si `hasMore` et rien n'est en cours ; en cas d'échec, garde la liste et renseigne `loadMoreErrorKey`.
- `toggleFavourite(String ticker)` : mise à jour immédiate de la carte (et retrait de la carte si `favouritesOnly`), appel `PUT` ou `DELETE`, retour à l'état précédent en cas d'échec (`favouriteErrorKey`, lu par l'écran pour le message).
- `favouriteChanged(String ticker, bool favourite)` : appelée par la fiche après un changement réussi ; met à jour la carte si elle est chargée (et la retire si `favouritesOnly` et `favourite` est faux).

Une réponse arrivée après un changement de critères est ignorée (compteur de requêtes), comme dans `EtfComparisonStore`.

### 7.2 `EtfDetailStore`

- `toggleFavourite()` : même principe que le catalogue (immédiat, appel, retour en arrière et `favouriteErrorKey` en cas d'échec).
- L'écran de la fiche écoute l'état (`BlocListener`) : quand un changement est confirmé, il appelle `EtfCatalogStore.favouriteChanged(ticker, favourite)`.

### 7.3 `EtfComparisonStore`

- `suggestEtfs(String search)` : renvoie les ETF de `repository.retrieveEtfs(search: search, size: 10)`, sans modifier l'état ; utilisé par le `suggestionsBuilder` du sélecteur. Échec : liste vide.
- Le reste ne change pas. Depuis la fiche, l'ETF A reste verrouillé.

## 8. Écran du catalogue (`lib/screens/compare/etf_catalog_screen.dart`)

### 8.1 Structure, de haut en bas

1. Bouton « Comparer deux ETFs » (existant).
2. `AppSearchBar` (« Rechercher un ETF par nom ou ticker ») et `FilterToggle` « Mes favoris » (icône étoile).
3. Rappel sur les ETF à effet de levier (8.3).
4. Bandeau de catalogue périmé (existant).
5. Liste des cartes, puis en bas : indicateur de chargement, ou message « Impossible de charger la suite. » avec « Réessayer ».

La page suivante est demandée quand la liste approche de sa fin (`ScrollController`, environ 300 pixels avant le bas).

### 8.2 États vides

| Situation | Message |
|---|---|
| Recherche sans résultat | Aucun ETF ne correspond à « van ». |
| Puce active, aucun favori | Aucun favori pour le moment. Touchez l'étoile d'un ETF pour l'ajouter. |
| Puce active et recherche, aucun résultat | Aucun favori ne correspond à « van ». |
| Ni recherche ni puce, catalogue vide | Aucun ETF disponible pour le moment. (existant) |

### 8.3 Rappel sur les ETF à effet de levier

Ligne discrète (`bodySmall`, couleur `onSurfaceVariant`, icône « i ») :

> Certains ETF amplifient (effet de levier) ou inversent les variations d'un indice : ils sont conçus pour des opérations de très court terme.

### 8.4 `EtfCard`

Nouveaux paramètres `isFavourite` et `onFavouriteTap` : étoile à droite (`Icons.star` / `Icons.star_border`, couleur `primary`). L'appui sur l'étoile n'ouvre pas la fiche.

## 9. Sélecteurs de la comparaison

- Widget **privé** `_EtfSearchField` dans `etf_comparison_screen.dart` (il ne sert qu'à cet écran), autour de `SearchAnchor` : libellé, pastille de couleur (`leading`), ticker sélectionné affiché, `suggestions` (`Future<List<({String ticker, String name})>> Function(String search)`), `onSelected`, désactivé si `onSelected` est `null`.
- Suggestion : « SPY · State Street SPDR S&P 500 ETF Trust ». L'écran filtre l'ETF choisi de l'autre côté avant de transmettre les suggestions.
- Recherche vide : aucune suggestion (pas d'appel).
- ETF A verrouillé depuis la fiche : le champ affiche le ticker et est désactivé.
- `SelectField` n'est plus utilisé : **supprimé** avec son test.
- `_EtfSelectors` ne lit plus `EtfCatalogStore`.

## 10. Fiche détail

- Étoile dans la barre du haut (`AppBar.actions`), mêmes icônes que la carte, visible une fois la fiche chargée.
- Message « Impossible de modifier les favoris. » (`SnackBar`) en cas d'échec.

## 11. Tests

Arborescence miroir de `lib/`. Aucun appel réel à l'API.

| Fichier | Contenu |
|---|---|
| `test/repositories/etf_repository_test.dart` | Paramètres envoyés (`page`, `size`, `search`, `favourites`, et leur absence) ; `favourite` lu ; `PUT` et `DELETE` sur la bonne URL ; erreur remontée |
| `test/stores/etf/etf_catalog_store_test.dart` | Page 0 ; `loadMore` ajoute la page suivante, s'arrête sans page restante, garde la liste en cas d'échec ; recherche envoyée après 300 ms et une seule fois pour plusieurs frappes ; puce ; réponse obsolète ignorée ; `toggleFavourite` (immédiat, confirmé, annulé en cas d'échec, carte retirée avec la puce) ; `favouriteChanged` |
| `test/stores/etf/etf_detail_store_test.dart` | `toggleFavourite` : immédiat, confirmé, annulé en cas d'échec |
| `test/stores/etf/etf_comparison_store_test.dart` | `suggestEtfs` : résultats, liste vide en cas d'échec |
| `test/screens/compare/etf_catalog_screen_test.dart` | Recherche, puce, rappel, états vides (8.2), chargement de la suite au défilement, erreur de la suite et « Réessayer », étoile et message d'échec |
| `test/screens/compare/etf_detail_screen_test.dart` | Étoile dans la barre du haut ; catalogue prévenu après un changement |
| `test/screens/compare/etf_comparison_screen_test.dart` | Adapté aux nouveaux sélecteurs : suggestions affichées et sélection, ETF de l'autre côté exclu, recherche vide sans appel, ETF A verrouillé |
| `test/widgets/card/etf_card_test.dart` | Étoile pleine ou vide ; appui sur l'étoile sans ouvrir la fiche |
| `test/fakes/fake_etf_repository.dart` | Nouvelles méthodes, appels enregistrés |

Rappel : `flutter test` compile les shaders avec `impellerc`, ce qui peut déclencher une demande d'autorisation macOS.

## 12. Suite : reprise du cache

Après le merge de ce plan, la branche `feat/mobile/api-cache` est mise à jour avec `main` :
- seule la **première page du catalogue sans recherche ni puce** est mise en cache ;
- hors ligne, la recherche, la puce, l'étoile et le chargement de la suite sont désactivés ;
- les fiches restent en cache comme prévu.

## 13. Découpage en commits

Branche `feat/mobile/catalog-search-favourites`, depuis `main` (après le merge du backend) :

- `✨ : mobile - search the etf catalog and pin favourites`

## 14. Critères de fin

- [ ] `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze` (aucun avertissement) et `flutter test` passent.
- [ ] Backend lancé depuis `main` : défilement de plusieurs pages, recherche « vanguard », épingler depuis la carte et depuis la fiche, puce « Mes favoris », comparaison en cherchant les deux ETF.
- [ ] Une erreur sur la page suivante ne vide jamais la liste affichée.
- [ ] Aucune couleur ni `TextStyle` en dur dans les nouveaux widgets.

---

## 15. Ajustements pendant le développement

| Sujet | Plan | Code livré | Raison |
|---|---|---|---|
| Branche | `feat/mobile/catalog-search-favourites`, après le merge du backend | Branche commune `feat/catalog-search-favourites`, un commit par projet | Décision de l'auteur : le backend et le mobile se testent ensemble |
| Fiche → catalogue | `BlocListener` qui prévient `EtfCatalogStore` | `EtfDetailStore.toggleFavourite()` renvoie l'état confirmé (`null` en cas d'échec) ; le bouton étoile de la fiche le transmet à `EtfCatalogStore.favouriteChanged` | Plus direct : un seul endroit sait que le changement a réussi |
| État du catalogue | Non précisé | `EtfCatalogState` ne garde plus `catalog` mais les champs utiles (`etfs`, `fetchedAt`, `stale`…) | Les ETF de plusieurs pages s'accumulent : la réponse d'une seule page ne suffit plus |
| Barre de recherche, puce et rappel | Au-dessus de la liste | Restent affichés pendant le chargement et en cas d'erreur de la première page | Pouvoir corriger sa recherche après une erreur |
| Ordre du catalogue | Bouton « Comparer deux ETFs », puis recherche | Recherche en premier, puis le bouton | Demande après les premiers essais |
| Pull to refresh | Hors périmètre | Sur le catalogue (première page, avec la recherche et la puce en cours) et sur la fiche. `refresh()` dans `EtfCatalogStore` et `EtfDetailStore` recharge sans afficher l'indicateur de chargement, pour laisser les données affichées pendant le rechargement | Demande après les premiers essais. Le geste recharge depuis le backend : il ne force pas d'appel à Twelve Data, dont la fréquence reste décidée par le backend |
| ETF à effet de levier ou inverses | Rappel général sous la recherche | En plus du rappel (complété : « Ceux repérés d'après leur nom portent une étiquette. »), étiquette `LeverageBadge` (`lib/widgets/badge/`) sur la carte et sous l'en-tête de la fiche, avec une bulle « i » sur la fiche. Champ `leveragedOrInverse` lu dans `EtfData` et `EtfDetailData` | Demande après les essais : le rappel seul ne permet pas de reconnaître ces ETF. Repérage fait par le backend (ADR backend 0003) |

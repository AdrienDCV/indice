# Plan d'implémentation : *pull-to-refresh* sur les ressources

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.

## Avant de coder

1. **Lis le code existant** : `lib/screens/learn/learn_screen.dart`, `lib/screens/learn/resource_detail_screen.dart`, `lib/stores/resource/resource_catalog_store.dart`, `lib/stores/resource/resource_detail_store.dart`, et leur équivalent côté ETF, qui propose déjà ce geste (`lib/screens/compare/etf_catalog_screen.dart`, `lib/screens/compare/etf_detail_screen.dart`, `lib/stores/etf/etf_catalog_store.dart`). Puis les tests : `test/stores/resource/`, `test/screens/learn/` et `test/fakes/fake_resource_repository.dart`.
2. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.

---

## 1. Objectif

Sur le catalogue et la fiche d'un ETF, tirer l'écran vers le bas le recharge. L'onglet Apprendre et la fiche d'une ressource ne proposent pas ce geste : pour voir une ressource ajoutée ou modifiée côté backend, il faut changer un filtre, modifier la recherche, rouvrir la fiche ou relancer l'application.

Désormais, comme côté ETF :
- **tirer la liste des ressources vers le bas recharge sa première page**, avec la recherche et les filtres en cours ;
- **tirer la fiche d'une ressource vers le bas la recharge**.

## 2. Hors périmètre

- Le rechargement automatique au retour en ligne : son fonctionnement ne change pas (voir la section 3).
- Le backend et le contrat d'API : inchangés.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Modèle | Reprendre le fonctionnement côté ETF : `RefreshIndicator` autour du contenu, `refresh()` dans le store |
| Affichage pendant le rechargement | Rechargement silencieux (`showLoading: false`) : seule la roue du geste s'affiche, le contenu actuel reste visible jusqu'à la réponse |
| Critères de la liste | La recherche, les niveaux et le filtre « Favoris » en cours sont conservés |
| Liste courte, vide ou en erreur | Le geste reste possible (`AlwaysScrollableScrollPhysics`) : il sert aussi à réessayer |
| Fiche en erreur | Pas de geste, comme sur la fiche d'un ETF : l'écran d'erreur a déjà son bouton « Réessayer » |
| Fiche courte (article bref) | Le geste reste possible (`AlwaysScrollableScrollPhysics`) |
| Vidéo en cours de lecture | Le lecteur est conservé pendant et après le rechargement : l'adresse de la vidéo ne change pas, la lecture continue |
| Hors ligne | Le geste reste possible, comme côté ETF : il relance la requête, et le bandeau disparaît si l'API répond |
| Retour en ligne automatique de la liste | Inchangé : il garde l'indicateur de chargement. Le catalogue d'ETF, lui, recharge sans indicateur. Aligner les deux sortirait du périmètre |

## 4. Liste des ressources

### Store (`ResourceCatalogStore`)

- Nouvelle méthode `refresh()`, qui appelle `_loadFirstPage(showLoading: false)`.
- `_loadFirstPage` reçoit un paramètre nommé `showLoading` (`true` par défaut) et l'utilise pour `isLoading` dans l'état émis avant la requête.
- Les autres appels (`init`, recherche, filtres, retour en ligne) ne changent pas.

### Écran (`LearnScreen`)

- La `ListView` de `_ResourcesView` est enveloppée dans un `RefreshIndicator` dont `onRefresh` appelle `store.refresh`.
- La `ListView` reçoit `physics: const AlwaysScrollableScrollPhysics()`.
- Le chargement de la page suivante (`_scrollController`) n'est pas modifié.

## 5. Fiche d'une ressource

### Store (`ResourceDetailStore`)

- Aucun changement : `refresh()` existe déjà (rechargement sans indicateur, utilisé par le retour en ligne).

### Écran (`ResourceDetailScreen`)

- Une fois la fiche chargée, `_DetailView` est enveloppée dans un `RefreshIndicator` dont `onRefresh` appelle `ResourceDetailStore.refresh`, comme dans `EtfDetailScreen`.
- Le `SingleChildScrollView` de `_DetailView` reçoit `physics: const AlwaysScrollableScrollPhysics()`.

## 6. Documentation

- `docs/plans/plan-implementation-offline-resources.md`, section 2 : une ligne renvoie vers ce plan pour le *pull-to-refresh*.

## 7. Tests

| Fichier | Cas |
|---|---|
| `test/stores/resource/resource_catalog_store_test.dart` | `refresh()` recharge la page 0 sans passer `isLoading` à `true`, et garde la liste affichée jusqu'à la réponse |
| `test/screens/learn/learn_screen_test.dart` | Tirer la liste vers le bas rappelle l'API et affiche les nouvelles ressources |
| `test/screens/learn/resource_detail_screen_test.dart` | Tirer la fiche vers le bas rappelle l'API et affiche la ressource mise à jour |
| Tests existants (filtres, recherche, hors ligne, retour en ligne, `ResourceDetailStore.refresh()`) | Doivent rester verts |

## 8. Découpage en commits

1. `💄 : mobile - add pull to refresh on the resources` (avec ce plan)

Le commit passe `flutter analyze` et `flutter test`.

## 9. Critères de fin

- Sur l'onglet Apprendre, tirer la liste vers le bas la recharge, avec les filtres et la recherche en cours.
- Sur la fiche d'une ressource, tirer l'écran vers le bas la recharge.
- Pendant le rechargement, le contenu reste affiché, sans grande roue de chargement.
- Le geste fonctionne aussi sur une liste vide, un écran d'erreur de la liste et une fiche courte.
- `flutter analyze` ne signale rien, et `flutter test` passe.

**Test manuel** : ouvrir l'onglet Apprendre, ajouter une ressource en base, tirer la liste vers le bas : elle apparaît. Recommencer avec un niveau sélectionné, puis l'API arrêtée (écran d'erreur, puis API relancée). Ouvrir une fiche, modifier son titre en base, tirer la fiche vers le bas : le nouveau titre s'affiche. Sur une vidéo en cours de lecture, tirer la fiche vers le bas : la lecture continue.

## 10. Ajustements pendant le développement

- **Plan écrit après l'implémentation de la liste** : le code de la liste a été écrit avant ce plan, qui a été demandé ensuite. La fiche a été ajoutée au périmètre à la relecture du plan, avant son implémentation.

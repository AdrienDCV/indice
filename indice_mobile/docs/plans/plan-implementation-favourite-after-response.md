# Plan d'implémentation : favori mis à jour après la réponse du backend

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.

## Avant de coder

1. **Lis le code existant** : `lib/stores/etf/etf_catalog_store.dart`, `lib/stores/etf/etf_detail_store.dart`, `lib/stores/resource/resource_catalog_store.dart`, `lib/stores/resource/resource_detail_store.dart`, leurs tests (`test/stores/`), `lib/widgets/favourite/favourite_icon.dart` et `test/fakes/`.
2. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.

---

## 1. Objectif

Aujourd'hui, l'étoile des favoris change **avant** la réponse du backend (affichage « optimiste ») : le store émet tout de suite l'état inversé, appelle l'API, puis remet l'ancienne valeur si l'API répond par une erreur.

Pendant la requête, l'écran affiche donc un favori que le backend n'a pas encore confirmé, et qui peut être annulé quelques instants plus tard : l'étoile se remplit, puis se vide.

L'étoile ne change donc plus qu'**après la réponse du backend**, qui reste la seule référence : l'écran n'affiche jamais un favori non confirmé.

**Limite connue, commune aux deux fonctionnements** : si la requête aboutit côté serveur mais que sa réponse n'arrive pas au téléphone (délai dépassé, réseau coupé au mauvais moment), l'application croit à un échec et l'étoile reste dans son ancien état, alors que le backend a enregistré le changement. L'affichage redevient juste au prochain chargement de l'écran. Ce cas ne serait couvert que par un rechargement de l'élément après une erreur (voir la section 2).

## 2. Hors périmètre

- Un mécanisme de resynchronisation (file d'attente des actions, renvoi au backend, gestion des conflits) : écarté, voir la section 3.
- Un rechargement de l'élément depuis le backend après une erreur, qui corrigerait le cas de la réponse perdue décrit en section 1 : possible plus tard, non demandé.
- Un indicateur de chargement sur l'étoile pendant la requête.
- Le backend et le contrat d'API : inchangés.
- Le mode hors ligne : épingler ou retirer un favori demande toujours le réseau, comme aujourd'hui.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Moment du changement | L'étoile change **après** la réponse de l'API, et seulement si elle réussit |
| En cas d'erreur | L'étoile ne bouge pas ; le message d'erreur actuel s'affiche (« Impossible de modifier les favoris. ») |
| Resynchronisation | Écartée : une file d'attente et une gestion des conflits représentent beaucoup de code pour une application à un seul utilisateur. Attendre la réponse garantit qu'aucun favori non confirmé n'est affiché |
| Appuis répétés | Tant qu'une requête est en cours pour un élément, les nouveaux appuis sur son étoile sont ignorés, pour ne pas envoyer deux requêtes contradictoires |
| Animation | Le rebond de `FavouriteIcon` suit le changement d'état : il se joue à la réponse du backend, et non plus au toucher. Aucun changement du widget |
| Stores concernés | Les quatre stores qui gèrent un favori : `EtfCatalogStore`, `EtfDetailStore`, `ResourceCatalogStore`, `ResourceDetailStore` |

## 4. Stores des fiches (`EtfDetailStore`, `ResourceDetailStore`)

`toggleFavourite()` :

1. Si l'élément n'est pas chargé, ou si une requête de favori est déjà en cours (`_favouritePending`, champ privé), renvoie `null` sans rien faire.
2. Émet un état qui efface la clé d'erreur de favori (`favouriteErrorKey: null`), pour que le message puisse s'afficher de nouveau en cas de seconde erreur.
3. Appelle le repository (`addFavourite` ou `removeFavourite`).
4. En cas de succès, émet l'état avec le favori inversé et renvoie la nouvelle valeur (l'écran prévient ensuite le catalogue avec `favouriteChanged`, comme aujourd'hui).
5. En cas d'erreur, émet seulement la clé d'erreur et renvoie `null`.
6. Dans tous les cas, remet `_favouritePending` à `false`.

## 5. Stores des catalogues (`EtfCatalogStore`, `ResourceCatalogStore`)

`toggleFavourite(id)` suit le même déroulé, avec un ensemble privé des identifiants en cours (`_pendingFavourites`), puisque plusieurs cartes peuvent être touchées à la suite.

En cas de succès, le store appelle `favouriteChanged(id, favourite)`, qui retrouve l'élément dans la liste **au moment de la réponse** : la mise à jour reste juste si la liste a été rechargée ou paginée entre-temps, et l'élément disparaît bien de la liste filtrée sur les favoris quand on le retire.

## 6. Documentation

- `docs/plans/plan-implementation-animations.md`, section 10 : une ligne indique que le rebond se joue désormais à la confirmation du backend.

## 7. Tests

| Fichier | Cas |
|---|---|
| `test/stores/etf/etf_catalog_store_test.dart` | L'étoile reste vide tant que l'API n'a pas répondu, puis se remplit ; un second appui pendant la requête est ignoré ; l'étoile ne bouge pas si l'API refuse (test existant renommé) |
| `test/stores/etf/etf_detail_store_test.dart` | Mêmes cas pour la fiche d'un ETF |
| `test/stores/resource/resource_catalog_store_test.dart` | Mêmes cas pour le catalogue des ressources |
| `test/stores/resource/resource_detail_store_test.dart` | L'étoile ne change qu'à la réponse, un second appui est ignoré ; l'étoile ne bouge pas si l'API refuse |
| Tests existants (écrans, filtre favoris, retrait d'un favori) | Doivent rester verts |

Les tests qui attendent la réponse utilisent un `Completer` dans les faux repositories, pour vérifier l'état avant et après la réponse.

## 8. Découpage en commits

1. `🐛 : mobile - update the favourite star after the backend response` (avec ce plan)

Le commit passe `flutter analyze` et `flutter test`.

## 9. Critères de fin

- Dans le catalogue d'ETF, sur une fiche ETF, dans la liste des ressources et sur une fiche ressource, l'étoile ne change qu'après la réponse du backend.
- Si le backend refuse, l'étoile ne bouge pas et le message d'erreur s'affiche.
- Deux appuis rapides n'envoient qu'une seule requête.
- `flutter analyze` ne signale rien, et `flutter test` passe.

## 10. Ajustements pendant le développement

- **Plan écrit après l'implémentation** : le code a été écrit avant ce plan, en sautant par erreur l'étape de validation. Le plan décrit ce qui a été décidé avec l'équipe avant le développement, et ce qui a été fait.

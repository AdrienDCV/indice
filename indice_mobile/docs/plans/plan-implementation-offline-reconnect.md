# Plan d'implémentation : retour en ligne détecté automatiquement

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.

## Avant de coder

1. **Lis le code existant** : `lib/stores/etf/etf_catalog_store.dart`, `lib/stores/etf/etf_detail_store.dart`, leurs tests (`test/stores/etf/`), `test/fakes/fake_etf_repository.dart` et `lib/repositories/etf_repository.dart` (`retrieveEtfs`, `retrieveEtf`).
2. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.

---

## 1. Objectif

Quand l'API ne répond pas, le catalogue d'ETF, le sélecteur d'ETF de la comparaison et la fiche d'un favori affichent les données téléchargées sur le téléphone, avec le bandeau « Hors ligne ».

Aujourd'hui, l'état hors ligne n'est recalculé qu'au chargement de l'écran : une recherche, un changement de filtre ou un *pull-to-refresh*. Quand l'API répond de nouveau, le bandeau reste affiché tant que l'utilisateur ne recharge pas l'écran lui-même.

Désormais, **tant qu'un écran est hors ligne, il réessaie de charger ses données toutes les 15 secondes**. Dès qu'une tentative réussit, il affiche les données de l'API et le bandeau disparaît.

## 2. Hors périmètre

- La détection d'un changement de réseau (paquet `connectivity_plus`) : écartée, voir la section 3.
- Une nouvelle tentative au retour de l'application au premier plan : écartée, la tentative périodique suffit.
- Un endpoint dédié pour vérifier l'état de l'API : non nécessaire, la tentative réutilise la requête de l'écran.
- Le backend et le contrat d'API : inchangés.
- La comparaison de deux ETF (`EtfComparisonStore`) : elle n'a pas de mode hors ligne.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Détection du retour en ligne | Relancer la requête de l'écran, et non surveiller le réseau du téléphone : `connectivity_plus` détecte le Wi-Fi, mais pas le retour d'une API arrêtée puis relancée, et ajouterait une dépendance |
| Fréquence | Une tentative 15 secondes après chaque chargement hors ligne. Le délai repart après la réponse : deux tentatives ne se chevauchent jamais |
| En ligne | Aucune tentative : le minuteur n'existe que lorsque l'écran est hors ligne |
| Affichage pendant la tentative | Rechargement silencieux (`showLoading: false`), comme le *pull-to-refresh* : pas d'indicateur de chargement ni de clignotement du bandeau |
| Filtre « Mes favoris » au retour en ligne | Désactivé : la tentative demande le catalogue complet. Si l'utilisateur avait activé le filtre avant la coupure, il doit le réactiver |
| Fermeture de l'écran | Le minuteur est annulé dans `close()` |
| Délai dans les tests | Paramètre nommé du constructeur (`reconnectDelay`, 15 secondes par défaut) que les tests remplacent par quelques millisecondes, sans ajouter de dépendance de test |

## 4. Catalogue et sélecteur (`EtfCatalogStore`)

Le catalogue et le sélecteur d'ETF utilisent chacun une instance de `EtfCatalogStore` : la modification couvre les deux écrans.

- Paramètre nommé du constructeur `reconnectDelay` (15 secondes par défaut), rangé dans le champ privé `_reconnectDelay`.
- Champ privé `Timer? _reconnectTimer`.
- À la fin de `_loadFirstPage`, si le résultat vient du téléphone (`result.offline`), le store programme `_reconnectTimer` pour une nouvelle tentative après `reconnectDelay`.
- Au début de chaque `_loadFirstPage`, le store annule le minuteur en cours : un rechargement lancé par l'utilisateur remplace la tentative prévue.
- La tentative recharge la première page **sans le filtre favoris** et sans indicateur de chargement. Si l'API répond, l'état passe à `offline: false` et `favouritesOnly: false`. Si elle ne répond toujours pas, le repository renvoie de nouveau les favoris téléchargés, l'état ne change pas et une nouvelle tentative est programmée.
- La synchronisation des favoris téléchargés (`syncFavouriteDownloads`) se lance au premier chargement en ligne, comme aujourd'hui : donc aussi au retour en ligne si l'écran a démarré hors ligne.
- `close()` annule le minuteur.

## 5. Fiche d'un ETF (`EtfDetailStore`)

La fiche est hors ligne lorsque `cachedAt` est renseigné.

- Même paramètre du constructeur et mêmes champs privés que le catalogue.
- À la fin de `_load`, si le résultat vient du téléphone (`result.cachedAt != null`), le store programme une tentative après `reconnectDelay`, qui appelle `refresh()`.
- Au début de chaque `_load`, le minuteur en cours est annulé.
- Si l'API répond, `cachedAt` repasse à `null` : le bandeau daté disparaît et l'étoile redevient active.
- `close()` annule le minuteur.

## 6. Documentation

- `docs/plans/plan-implementation-api-cache.md`, section des ajustements : une ligne renvoie vers ce plan pour le retour en ligne.

## 7. Tests

| Fichier | Cas |
|---|---|
| `test/stores/etf/etf_catalog_store_test.dart` | Hors ligne, le store recharge le catalogue après le délai ; au retour de l'API, `offline` et `favouritesOnly` repassent à `false` ; tant que l'API ne répond pas, il réessaie ; en ligne, aucune nouvelle requête après le délai ; aucune requête après `close()` |
| `test/stores/etf/etf_detail_store_test.dart` | Hors ligne, la fiche se recharge après le délai et `cachedAt` repasse à `null` au retour de l'API ; en ligne, aucune nouvelle requête ; aucune requête après `close()` |
| Tests existants (écrans, mode hors ligne, favoris) | Doivent rester verts |

Les faux repositories passent de hors ligne à en ligne en modifiant `catalogOffline` et `detailCachedAt` entre deux tentatives.

## 8. Découpage en commits

1. `🐛 : mobile - hide the offline bar once the api answers again` (avec ce plan)

Le commit passe `flutter analyze` et `flutter test`.

## 9. Critères de fin

- Catalogue, sélecteur ou fiche d'un favori ouverts hors ligne : moins de 20 secondes après le redémarrage de l'API, le bandeau disparaît sans action de l'utilisateur.
- Au retour en ligne, le catalogue affiche tous les ETF, filtre « Mes favoris » désactivé.
- En ligne, aucune requête n'est envoyée en arrière-plan.
- `flutter analyze` ne signale rien, et `flutter test` passe.

**Test manuel** : lancer l'application sans l'API ; le catalogue affiche les favoris téléchargés avec le bandeau. Démarrer l'API : le bandeau disparaît en moins de 20 secondes et le catalogue complet s'affiche. Même essai sur la fiche d'un favori et dans le sélecteur de la comparaison.

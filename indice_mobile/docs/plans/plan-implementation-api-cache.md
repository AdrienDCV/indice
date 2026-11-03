# Plan d'implémentation : favoris consultables hors ligne

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Il remplace la première version de ce plan (cache des réponses : catalogue et fiches consultées), devenue inadaptée avec le catalogue complet de plus de 11 000 ETF.

## Avant de coder

1. **Lis le code existant** : `lib/storage/api_cache.dart`, `lib/repositories/`, `lib/stores/etf/`, `lib/screens/compare/etf_catalog_screen.dart`, `lib/screens/compare/etf_detail_screen.dart`, `lib/utils/offline_message.dart`, `test/fakes/`, et côté backend `EtfController`, `EtfService`, `EtfDetailService`.
2. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.

---

## 1. Objectif

Répondre au §6 du sujet (« Fonctionnement hors connexion ») sur le modèle des **téléchargements de Spotify et Deezer** : l'utilisateur choisit ce qu'il garde, et ses choix forment sa bibliothèque hors ligne. Ici, **épingler un ETF en favori, c'est le télécharger** : sa fiche est enregistrée sur le téléphone. Sans réseau, y compris après une fermeture complète de l'application, l'utilisateur retrouve la liste de ses favoris et la fiche de chacun, avec la date et l'heure de dernière récupération.

## 2. Hors périmètre

- Le reste du catalogue hors ligne (recherche, pages, ETF non favoris) : seuls les favoris sont disponibles.
- La comparaison hors ligne : elle affiche son erreur habituelle.
- Le rafraîchissement automatique des fiches déjà téléchargées : une fiche est mise à jour quand on la rouvre en ligne.
- Les modifications de favoris hors ligne (étoile désactivée sans réseau).
- Une limite du nombre de fiches téléchargées (section 3).

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Ce qui est gardé | **Uniquement les fiches des favoris**, une par fichier (`api_cache/etf_detail_<TICKER>.json`, format inchangé : `cachedAt` et la réponse brute de l'API). Plus de cache du catalogue ni des fiches non favorites |
| Téléchargement | **À l'épinglage** : `PUT /etfs/{ticker}/favourite` répond 200 avec la fiche (section 4), enregistrée aussitôt. **À chaque ouverture en ligne** d'une fiche favorite : le fichier est mis à jour |
| Suppression | Au retrait du favori (`DELETE` réussi) : le fichier est supprimé, comme on supprime un téléchargement |
| Synchronisation | Au démarrage, en ligne : l'application récupère la liste des favoris (`GET /etfs?favourites=true`), **télécharge les fiches manquantes** (`GET /etfs/{ticker}`) et **supprime les fichiers des ETF qui ne sont plus favoris**. Elle ne rafraîchit pas les fiches déjà présentes (crédits Twelve Data, 8 appels par minute au plus) |
| Hors ligne, catalogue | Il affiche les favoris téléchargés, triés par nom, construits à partir des fichiers. Bandeau « Hors ligne : seuls vos favoris téléchargés sont disponibles. ». Recherche et étoiles désactivées, puce « Mes favoris » affichée active et verrouillée, pas de chargement de la suite |
| Hors ligne, fiche d'un favori | Lue dans son fichier, avec le bandeau daté existant (« Hors ligne : dernières données récupérées le 30/10/2026 à 14:05. »). Étoile désactivée |
| Hors ligne, fiche non favorite | Erreur habituelle (aucune fiche n'est gardée) |
| Limite | **Aucune.** Le volume est borné par les choix de l'utilisateur, qui le libère en retirant un favori. Une fiche pèse environ 75 Ko : 100 favoris représentent environ 7,5 Mo |
| Erreurs qui déclenchent la lecture des fichiers | Inchangées : erreur réseau, délai dépassé ou 5xx, jamais une 4xx |
| Stockage | Inchangé : fichiers dans le dossier cache de l'application (`path_provider`). ADR-0001 réécrite (section 9) |

## 4. Backend : `PUT /etfs/{ticker}/favourite` renvoie la fiche

**Changement du contrat d'API, sans rien casser côté mobile** : le `PUT` répond désormais **toujours 200**, avec la fiche de l'ETF au même format que `GET /etfs/{ticker}` (`EtfDetailResponseDto`, avec `favourite: true`). Il répondait jusqu'ici 201 au premier épinglage et 200 ensuite, sans corps ; le mobile actuel ne lit ni le statut ni le corps.

**Pourquoi 200 et plus 201** : 200 est la seule réponse juste à chaque appel. Un deuxième `PUT` ne crée rien, et la même requête renvoie ainsi toujours la même réponse (idempotence complète). C'est aussi le code courant d'un `PUT` qui renvoie un contenu. L'écart avec la norme (MDN : *« must send a 201 Created response »* quand le `PUT` crée la ressource) est assumé : le mobile ne distingue pas les deux cas. L'ADR backend 0002, qui mentionne 201 et 200, garde sa décision (favoris côté backend, utilisateur unique) ; ce détail de code HTTP est consigné ici.

- La fiche est calculée comme celle de `GET /etfs/{ticker}` : si les cours ont plus d'un jour, l'épinglage déclenche un appel Twelve Data, et si Twelve Data est indisponible, la fiche est renvoyée avec `stale = true` (le favori est enregistré dans tous les cas).
- `EtfService.addFavourite(ticker)` épingle l'ETF comme aujourd'hui, puis renvoie sa fiche, récupérée avec `EtfDetailService.retrieveEtf` (même domaine). Le controller la convertit en `EtfDetailResponseDto`.
- `DELETE` ne change pas (204 sans corps).
- Tests : `EtfServiceTest` (fiche renvoyée, que l'ETF soit déjà épinglé ou non), `EtfControllerTest` (200 avec la fiche dans le JSON).

## 5. Stockage (`lib/storage/api_cache.dart`)

`ApiCache` garde `write` et `read`, et reçoit :
- `delete(key)` : supprime le fichier, sans erreur s'il n'existe pas ;
- `readAll(prefix)` : lit tous les fichiers dont la clé commence par le préfixe (`etf_detail_`), en ignorant les illisibles.

## 6. Repository (`lib/repositories/etf_repository.dart`)

| Méthode | Comportement |
|---|---|
| `retrieveEtfs(...)` | Plus aucun cache. En cas d'erreur réseau ou 5xx sur la **première page sans recherche**, renvoie les favoris téléchargés : `CachedResult(catalogue construit à partir des fiches téléchargées, triées par nom, offline: true)`, même vide. Sinon l'erreur remonte |
| `retrieveEtf(ticker)` | En ligne : si la fiche est favorite, elle est enregistrée ; sinon, un éventuel ancien fichier est supprimé. Erreur réseau ou 5xx : lecture du fichier s'il existe |
| `addFavourite(ticker)` | `PUT`, puis enregistrement de la fiche renvoyée |
| `removeFavourite(ticker)` | `DELETE`, puis suppression du fichier |
| `syncFavouriteDownloads()` (nouveau) | Liste des favoris (`GET /etfs?favourites=true`, pages de 100), téléchargement des fiches manquantes, suppression des fichiers en trop. Les échecs sont ignorés (nouvelle tentative au prochain démarrage) |

La construction du catalogue hors ligne recopie les champs des fiches (`ticker`, `name`, `exchange`, `currency`, `favourite`, `leveragedOrInverse`) dans des `EtfData` : aucune donnée n'est calculée.

## 7. Stores et démarrage

- `EtfCatalogStore` : quand la première page vient des favoris téléchargés (`offline`), `favouritesOnly` est affiché actif. Après le premier chargement réussi en ligne, il lance `syncFavouriteDownloads()` sans l'attendre.
- `EtfDetailStore` : inchangé (`cachedAt` déjà géré).

## 8. Écrans

- **Catalogue hors ligne** : bandeau « Hors ligne : seuls vos favoris téléchargés sont disponibles. » à la place du bandeau périmé ; recherche, étoiles et puce désactivées (puce affichée active) ; si aucun favori n'est téléchargé : « Aucun favori disponible hors ligne. Épinglez un ETF pour le retrouver sans connexion. ».
- **Fiche hors ligne** : inchangée (bandeau daté, étoile désactivée).

## 9. Documentation

- **ADR-0001 réécrite** (jamais mergée) : « Favoris consultables hors ligne, enregistrés en fichiers locaux ». Contexte : §6 du sujet, catalogue de plus de 11 000 ETF. Décision : modèle des téléchargements de Spotify et Deezer, citées d'après leurs pages d'aide officielles (**vérifiées avant d'être citées**). Alternatives : cache des réponses (première version, inadaptée au catalogue paginé), SQLite (inutile pour un ensemble choisi par l'utilisateur et consulté sans recherche), limite du nombre de fiches (sans justification).
- **Glossaire** (`indice-backend/docs/glossaire.md`) : « Favori » complété (la réponse du `PUT` porte la fiche, le mobile la garde hors ligne).
- `CLAUDE.md` mobile : la règle sur `ApiCache` décrit les favoris téléchargés.

## 10. Tests

| Fichier | Contenu |
|---|---|
| `test/storage/api_cache_test.dart` | `delete` (fichier présent ou absent) ; `readAll` (préfixe, fichiers illisibles ignorés) |
| `test/repositories/etf_repository_test.dart` | Épingler enregistre la fiche renvoyée ; retirer supprime le fichier ; fiche favorite ouverte en ligne enregistrée, non favorite non enregistrée (et ancien fichier supprimé) ; fiche hors ligne lue dans son fichier ; catalogue hors ligne = favoris téléchargés triés par nom ; recherche hors ligne → erreur ; 4xx → erreur ; synchronisation (télécharge les manquantes, supprime les fichiers en trop, ignore les échecs) |
| `test/stores/etf/etf_catalog_store_test.dart` | Puce affichée active avec les favoris téléchargés ; synchronisation lancée après le premier chargement en ligne, pas hors ligne |
| `test/screens/compare/etf_catalog_screen_test.dart` | Bandeau hors ligne, commandes désactivées, message sans favori téléchargé |
| Backend | Section 4 |

**Test manuel** : en ligne, épingler deux ETF (un depuis une carte, un depuis sa fiche) ; couper le réseau, fermer puis rouvrir l'application : le catalogue affiche ces deux favoris avec le bandeau, leurs fiches s'ouvrent avec la date ; une fiche non favorite affiche l'erreur habituelle. Rétablir le réseau, retirer un favori : son fichier disparaît.

---

## 11. Découpage en commits

Branche `feat/mobile/api-cache` :

- `✨ : backend - return the etf detail when pinning a favourite`
- `✨ : mobile - keep favourite etfs available offline` (remplace le commit `WIP` actuel)

## 12. Critères de fin

- [ ] `./mvnw clean test` et `flutter analyze` / `flutter test` passent.
- [ ] Test manuel de la section 10 réalisé sur un appareil.
- [ ] Aucune fiche non favorite n'est gardée sur le téléphone.
- [ ] ADR-0001 réécrite, sources Spotify et Deezer vérifiées.

---

## 13. Ajustements pendant le développement

| Sujet | Plan | Code livré | Raison |
|---|---|---|---|
| Signal « hors ligne » | `cachedAt` non nul | `CachedResult.offline` (booléen), distinct de `cachedAt` (date d'enregistrement d'une fiche). Le catalogue hors ligne n'a pas de date ; un catalogue hors ligne vide affiche « Aucun favori disponible hors ligne. Épinglez un ETF pour le retrouver sans connexion. » | Une date ne doit pas servir d'indicateur : sans fiche téléchargée, il n'y avait aucune date à donner, et le message prévu ne pouvait pas s'afficher |
| Nom de l'ADR | `0001-cache-api-en-fichiers-locaux.md` | `0001-favoris-consultables-hors-ligne.md` | Le nom suit la décision réécrite |
| `ApiCache.readAll` | Fichiers illisibles ignorés | Idem, et liste vide si le dossier n'existe pas encore | Premier lancement, ou dossier vidé par le système |
| Bandeau hors ligne | `StaleDataBanner` arrondi dans la liste | `OfflineBar` (`lib/widgets/banner/`) : bande pleine largeur et sombre (`inverseSurface`), icône `cloud_off`, collée en haut de l'écran et hors de la liste (elle ne défile pas). Catalogue : « Hors ligne · seuls vos favoris téléchargés sont disponibles » ; fiche : « Hors ligne · données du 02/11/2026 à 21:17 » (`offlineMessage`) | Demande après les essais : un bandeau plus « brut », sur le modèle des applications qui signalent l'absence de connexion |

# Plan d'implémentation : ressources favorites consultables hors ligne

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.

## Avant de coder

1. **Lis le code existant** : `lib/repositories/etf_repository.dart` (téléchargement des favoris), `lib/repositories/resource_repository.dart`, `lib/storage/api_cache.dart`, `lib/stores/etf/etf_catalog_store.dart` et `etf_detail_store.dart` (mode hors ligne et reconnexion), les stores et écrans des ressources (`lib/stores/resource/`, `lib/screens/learn/`, `lib/pages/home_page.dart`), leurs tests et `test/fakes/fake_resource_repository.dart`.
2. **Lis** `docs/adr/0001-favoris-consultables-hors-ligne.md` et `docs/plans/plan-implementation-api-cache.md`.
3. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.

---

## 1. Objectif

Les fiches des ETF favoris sont consultables hors ligne (ADR 0001), mais rien n'est gardé côté ressources : sans réseau, l'onglet Apprendre et les fiches de ressources affichent une erreur.

Les ressources suivent désormais la même règle que les ETF : **épingler une ressource, c'est la télécharger**. On donne la priorité à ce que l'utilisateur veut pouvoir consulter rapidement : ses favoris.

Il y a 6 ressources : 3 articles, dont le contenu est du texte, entièrement lisible hors ligne, et 3 vidéos YouTube, dont le titre, la description et le texte restent lisibles, mais pas la vidéo, qui demande le réseau.

## 2. Hors périmètre

- Les miniatures des vidéos : sujet séparé, sur ses propres branches (backend puis mobile).
- La lecture d'une vidéo hors ligne : une vidéo YouTube ne se télécharge pas (conditions d'utilisation de YouTube) et le lecteur intégré demande le réseau.
- Les ressources non favorites, la recherche et les filtres de niveau hors ligne.
- Le backend et le contrat d'API : inchangés.
- Un *pull-to-refresh* sur l'onglet Apprendre ou la fiche d'une ressource.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Ce qui est gardé | Les fiches des ressources favorites seulement, comme pour les ETF : priorité à ce que l'utilisateur veut consulter rapidement |
| Téléchargement à l'épinglage | Après `PUT /resources/{id}/favourite`, le repository demande la fiche (`GET /resources/{id}`) et l'enregistre. Pas de changement du backend : une fiche de ressource ne coûte aucun appel à Twelve Data, contrairement à celle d'un ETF |
| Échec du téléchargement après l'épinglage | Le favori reste enregistré ; la fiche sera téléchargée au prochain démarrage en ligne |
| Fichiers | `api_cache/resource_detail_<id>.json`, avec `ApiCache` comme pour les ETF |
| Onglet Apprendre hors ligne | Comme le catalogue d'ETF : bandeau « Hors ligne · seuls vos favoris téléchargés sont disponibles », favoris téléchargés triés par titre, recherche, filtres de niveau et étoiles désactivés, filtre Favoris affiché actif. Le mobile ne filtre rien lui-même |
| Accueil hors ligne | La section « Nouveauté pédagogique » affiche « Hors ligne : retrouvez vos favoris dans Apprendre. » à la place des cartes, pour ne pas présenter des favoris comme des nouveautés |
| Fiche hors ligne | Bandeau daté existant (« Hors ligne · données du … à … »), étoile désactivée |
| Vidéo hors ligne | La vignette habituelle (`ResourceThumbnail`), suivie de « La vidéo demande une connexion. » ; le texte de la fiche reste lisible |
| Retour du réseau | Comme pour les ETF : nouvel essai toutes les 15 secondes tant que l'écran est hors ligne ; au retour, le filtre Favoris est désactivé |
| Documentation | Nouvel ADR 0002, qui s'appuie sur l'ADR 0001 sans le modifier |

## 4. Repository (`lib/repositories/resource_repository.dart`)

`ResourceRepository` reçoit `ApiCache` (comme `EtfRepository`) ; `lib/injection.dart` le lui passe.

- `retrieveResources(...)` renvoie un `CachedResult<PaginatedData<ResourceData>>`. Si l'API est injoignable (pas de réponse ou erreur 5xx) pour la première page sans recherche ni filtre de niveau, il renvoie les ressources téléchargées, triées par titre, avec `offline: true`. Dans les autres cas, l'erreur remonte comme aujourd'hui.
- `retrieveResource(id)` renvoie un `CachedResult<ResourceDetailData>`. En ligne, il enregistre la fiche si elle est favorite et supprime son fichier sinon. Si l'API est injoignable, il lit le fichier et renvoie la fiche avec sa date (`cachedAt`) ; sans fichier, l'erreur remonte.
- `addFavourite(id)` appelle `PUT`, puis télécharge la fiche avec `retrieveResource(id)` ; une erreur de ce second appel est ignorée.
- `removeFavourite(id)` appelle `DELETE`, puis supprime le fichier.
- `syncFavouriteDownloads()` : télécharge les fiches des favoris qui manquent et supprime celles des ressources qui ne sont plus favorites, comme pour les ETF. Les erreurs sont ignorées.

Les erreurs 4xx ne lisent jamais les fichiers.

## 5. Stores

### `ResourceCatalogStore`

- État : nouveau champ `offline`.
- Hors ligne : `favouritesOnly` affiché à `true`, pas de chargement de la suite.
- Nouvelle tentative 15 secondes après chaque chargement hors ligne, sans le filtre favoris (paramètre nommé `reconnectDelay`, comme `EtfCatalogStore`) ; annulée par un nouveau chargement et par `close()`.
- `syncFavouriteDownloads()` est lancé une fois, après le premier chargement en ligne.

### `ResourceDetailStore`

- État : nouveau champ `cachedAt`.
- Nouvelle méthode `refresh()` (rechargement sans indicateur de chargement).
- Nouvelle tentative 15 secondes après chaque chargement hors ligne (`reconnectDelay`), annulée par un nouveau chargement et par `close()`.

## 6. Écrans et composants

- `lib/utils/offline_message.dart` : le message « Hors ligne · seuls vos favoris téléchargés sont disponibles », aujourd'hui dupliqué dans le catalogue et le sélecteur d'ETF, y est rangé pour servir une troisième fois.
- `ResourceCard` : `onFavouriteTap` devient facultatif (`null` désactive l'étoile), comme `EtfCard`.
- `LearnScreen` : `OfflineBar` en haut, recherche et filtres désactivés, étoiles désactivées. Liste vide hors ligne : « Aucun favori disponible hors ligne. Épinglez une ressource pour la retrouver sans connexion. »
- `HomePage` : hors ligne, la section « Nouveauté pédagogique » affiche « Hors ligne : retrouvez vos favoris dans Apprendre. » à la place des cartes.
- `ResourceDetailScreen` : `OfflineBar(offlineMessage(cachedAt))` si `cachedAt` est renseigné ; étoile désactivée ; à la place du lecteur vidéo, `ResourceThumbnail` et « La vidéo demande une connexion. ».

## 7. Documentation

- `docs/adr/0002-ressources-favorites-consultables-hors-ligne.md`, à partir de `0000-template.md` : contexte, décision (priorité aux favoris, que l'utilisateur veut consulter rapidement), alternatives (garder toutes les ressources ; faire renvoyer la fiche par `PUT`), conséquences (vidéos non lisibles hors ligne).
- `docs/adr/README.md` : ligne 0002 dans l'index.

## 8. Tests

| Fichier | Cas |
|---|---|
| `test/repositories/resource_repository_test.dart` | Fiche favorite enregistrée, fiche non favorite supprimée ; fiche lue hors ligne avec sa date ; erreur 4xx sans lecture du fichier ; catalogue hors ligne trié par titre ; pas de lecture hors ligne pour une recherche, un filtre ou la page 2 ; épinglage qui télécharge la fiche, même si le téléchargement échoue ; retrait qui supprime le fichier ; synchronisation au démarrage |
| `test/stores/resource/resource_catalog_store_test.dart` | État hors ligne et filtre Favoris actif ; pas de suite hors ligne ; retour en ligne après le délai ; aucune tentative en ligne ni après `close()` ; synchronisation lancée une fois en ligne, jamais hors ligne |
| `test/stores/resource/resource_detail_store_test.dart` | `cachedAt` hors ligne ; `refresh()` ; retour en ligne après le délai ; aucune tentative en ligne ni après `close()` |
| `test/screens/learn/learn_screen_test.dart` | Bandeau, commandes désactivées, message sans favori téléchargé |
| `test/screens/learn/resource_detail_screen_test.dart` | Bandeau daté, étoile désactivée, vignette et message à la place de la vidéo |
| `test/pages/home_page_test.dart` | Cartes en ligne ; message à la place des cartes hors ligne |
| Tests existants | Doivent rester verts |

## 9. Découpage en commits

1. `✨ : mobile - download favourite resources for offline reading` : repository, stores, ADR 0002 et ce plan.
2. `✨ : mobile - show favourite resources offline` : écrans et composants.

Chaque commit passe `flutter analyze` et `flutter test`.

## 10. Critères de fin

- Une ressource épinglée en ligne reste consultable après coupure du réseau et redémarrage de l'application, avec la date de sa dernière récupération.
- Hors ligne, l'onglet Apprendre affiche les favoris téléchargés avec le bandeau, et l'accueil affiche son message.
- Une vidéo hors ligne affiche sa vignette et son message, et son texte reste lisible.
- Au retour du réseau, les bandeaux disparaissent en moins de 20 secondes.
- `flutter analyze` ne signale rien, et `flutter test` passe.

**Test manuel** : en ligne, épingler un article et une vidéo (l'un depuis une carte, l'autre depuis sa fiche) ; couper le réseau, fermer puis rouvrir l'application : l'onglet Apprendre affiche ces deux favoris avec le bandeau, l'accueil affiche son message, les fiches s'ouvrent avec leur date, la vidéo affiche sa vignette et son message. Rétablir le réseau : les bandeaux disparaissent.

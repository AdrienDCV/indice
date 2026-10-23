# Plan d'implémentation : catalogue des ETF (onglet Comparer)

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Premier des trois plans du module Comparer : **catalogue** (ce plan), puis **détail d'un ETF**, puis **comparaison de deux ETF**.

## Avant de coder

1. **Lis le code existant** : `lib/main.dart`, `lib/router.dart`, `lib/pages/main_page.dart`, `lib/theme/app_theme.dart`, `test/widget_test.dart`.
2. **Lis le contrat de l'API** dans `../indice-backend` : `EtfController`, `EtfCatalogResponseDto`, `EtfResponseDto`, `PageResponseDto`, `ExceptionController`.
3. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.

---

## 1. Objectif

Afficher dans l'onglet **Comparer** la liste des ETF du catalogue renvoyée par `GET /api/etfs`.

Ce plan pose aussi le **socle commun** aux trois écrans du module (injection, configuration, appels à l'API, erreurs, pagination). La navigation go_router est déjà en place (PR #14).

## 2. Hors périmètre

- Le détail d'un ETF : un appui sur une carte ne fait rien pour l'instant (plan 2).
- La migration de `lib/pages/` et `lib/models/` vers les nouvelles conventions : refactoring dédié.
- La recherche et les filtres : inutiles avec 10 ETF triés par nom.
- La pagination côté interface (défilement infini, « charger plus »).
- Le pull-to-refresh.
- Le style définitif : les maquettes Figma ne sont pas encore accessibles. On utilise le thème existant, et le style sera ajusté plus tard.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Socle | get_it, `.env.local` / `.env.example`, `ApiException`, `lib/errors/`, `PaginatedData<T>`, client `http`. **Aucune nouvelle dépendance** : tous les paquets sont déjà dans `pubspec.yaml` |
| Navigation | Déjà en place (PR #14). La branche `/compare` affiche `EtfCatalogScreen` à la place de `ComparePage` |
| Store | `EtfCatalogStore`, un store par notion, **fourni au niveau de l'app** et créé paresseusement : partagé par le catalogue et, au plan 3, par le choix des ETF à comparer. Pas d'`AppStore` global unique (il grossirait à chaque fonctionnalité) |
| Chargement | Un seul appel `GET /etfs?size=100`, le maximum accepté par le backend. Le catalogue compte 10 ETF |
| Carte | `EtfCard` : nom, ticker, place de cotation · devise. Ni prix ni performance (le catalogue ne les renvoie pas) |
| Catalogue périmé | Bandeau affiché seulement si `stale` vaut `true`, avec la date de `fetchedAt` si elle n'est pas `null` |
| Erreurs | La clé est lue dans le champ **`message`** de la réponse d'erreur. Bouton « Réessayer » qui rappelle `init()` |
| Réseau | Aucune configuration Android ni iOS pour le HTTP en clair (voir 4.3), vérifiée au premier lancement |
| Formatage de date | Extension maison dans `lib/utils/`, sans `intl` |
| Tests | Repository (`MockClient`), store (faux repository écrit à la main), widgets, screen, extension de date. Ni mocktail ni bloc_test |

---

## 4. Contrat de l'API

### 4.1 Succès : `GET /api/etfs?size=100`

```json
{
  "etfs": {
    "content": [
      { "ticker": "BND", "exchange": "NASDAQ", "name": "Vanguard Total Bond Market ETF", "currency": "USD" }
    ],
    "page": 0,
    "size": 100,
    "totalElements": 10,
    "totalPages": 1
  },
  "fetchedAt": "2026-10-07T08:00:00Z",
  "stale": false
}
```

- Tri par nom côté backend (`@PageableDefault(sort = ["name"])`), conservé tel quel.
- `fetchedAt` : date de la dernière synchronisation réussie avec Twelve Data, en UTC. **Nullable** (catalogue jamais synchronisé).
- `stale = true` : la synchronisation a échoué, et la liste date de `fetchedAt`.
- **Limite connue** : au-delà de 100 ETF, seuls les 100 premiers s'affichent. Il faudra alors charger les pages suivantes.

### 4.2 Erreur

Le corps est toujours une **liste**. La **clé** est dans `message`, et `error` contient le libellé HTTP :

```json
[{ "error": "Internal Server Error", "message": "error.unexpected" }]
```

Le `CLAUDE.md` mobile indique à tort que la clé est dans `error` : il est corrigé par ce plan (section 11).

Toutes les exceptions métier du backend passent leur clé comme message. Seules les erreurs de validation (`@Valid`) mettraient un texte libre dans `message`, mais aucun endpoint n'en utilise aujourd'hui. Un texte inconnu de la table des messages donne le message générique.

Seule clé atteignable depuis cet écran : `error.unexpected`. Les plans 2 et 3 ajouteront les leurs.

### 4.3 HTTP en clair

Android bloque le HTTP en clair par défaut depuis Android 9, mais cette règle ne vise que les sockets natifs de la plateforme. Le paquet `http` passe par `dart:io`, dont les sockets appartiennent à Dart :

- [doc Android](https://developer.android.com/privacy-and-security/security-config) : « Starting with Android 9 (API level 28), cleartext support is disabled by default. »
- [doc Flutter](https://docs.flutter.dev/release/breaking-changes/network-policy-ios-android) : « If the socket is owned by Dart/Flutter, no policy will be enforced. »

On n'ajoute donc ni `usesCleartextTraffic`, ni exception ATS. **À vérifier au premier lancement** sur l'émulateur Android et sur le simulateur iOS. En cas d'échec, ajouter une exception limitée au debug et mettre à jour ce plan.

---

## 5. Configuration (`.env`)

- `.env.example` (versionné) :

  ```bash
  API_BASE_URL=
  ```
- `.env.local` (ignoré par Git, déjà couvert par `.env.*` dans `.gitignore`) : copie de `.env.example` avec l'URL remplie, context path `/api` compris : `http://localhost:8080/api` sur le simulateur iOS, `http://10.0.2.2:8080/api` sur l'émulateur Android. Ces valeurs sont indiquées dans le README.
- `pubspec.yaml` : déclarer `.env.local` dans `flutter.assets`. **Sans ce fichier, la compilation échoue** : le signaler dans le README (section 11).
- `main()` : `await dotenv.load(fileName: '.env.local')` avant l'injection.

---

## 6. Navigation

La navigation go_router est en place depuis la PR #14 (`lib/router.dart`, `StatefulShellRoute.indexedStack`). Ce plan ne change que le `builder` de la route `/compare`, qui affiche `EtfCatalogScreen` au lieu de `ComparePage`.

Une branche n'est construite qu'à sa première visite (`preload` vaut `false` par défaut, [doc go_router](https://pub.dev/documentation/go_router/latest/go_router/StatefulShellBranch/preload.html) : « the branch will only be loaded when needed »). Combiné à la création paresseuse du store (section 10.3), le catalogue n'est appelé qu'à l'ouverture de l'onglet Comparer.

---

## 7. Socle

### 7.1 Erreurs (`lib/errors/`)

- `api_exception.dart` : `ApiException implements Exception`, avec `final List<String> errorKeys`.
- `error_messages.dart` : table clé → message français, et une fonction `String errorMessage(String key)` qui renvoie le message générique pour une clé inconnue.

  | Clé | Message |
  |---|---|
  | `error.unexpected` | « Une erreur inattendue est survenue. Réessaie dans quelques instants. » |
  | *(générique)* | « Une erreur est survenue. Réessaie dans quelques instants. » |

  Le tutoiement suit le ton de l'app (« Prêt à découvrir l'investissement ? »). À confirmer à la relecture.

### 7.2 Pagination (`lib/models/common/paginated_data.dart`)

`PaginatedData<T>`, `@Freezed(genericArgumentFactories: true)`, champs `content`, `page`, `size`, `totalElements`, `totalPages` (tous non nullables, comme `PageResponseDto`).

```dart
factory PaginatedData.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
    _$PaginatedDataFromJson(json, fromJsonT);
```

### 7.3 Injection (`lib/injection.dart`)

```dart
final getIt = GetIt.instance;

void configureDependencies() {
  final apiBaseUrl = dotenv.get('API_BASE_URL');
  getIt
    ..registerLazySingleton<http.Client>(http.Client.new)
    ..registerLazySingleton(() => EtfRepository(getIt(), apiBaseUrl));
}
```

Appelée dans `main()` après `dotenv.load`, avant `runApp`. `dotenv.get` lève une erreur si la clé est absente : l'app échoue au démarrage avec un message clair, plutôt qu'à la première requête.

---

## 8. Données (`lib/models/etf/`)

`etf_data.dart` :

```dart
@freezed
abstract class EtfData with _$EtfData {
  const factory EtfData({
    required String ticker,
    required String exchange,
    required String name,
    required String currency,
  }) = _EtfData;

  factory EtfData.fromJson(Map<String, dynamic> json) => _$EtfDataFromJson(json);
}
```

`etf_catalog_data.dart` :

```dart
@freezed
abstract class EtfCatalogData with _$EtfCatalogData {
  const factory EtfCatalogData({
    required PaginatedData<EtfData> etfs,
    DateTime? fetchedAt,
    required bool stale,
  }) = _EtfCatalogData;

  factory EtfCatalogData.fromJson(Map<String, dynamic> json) => _$EtfCatalogDataFromJson(json);
}
```

- `fetchedAt` : json_serializable convertit la chaîne ISO (`2026-10-07T08:00:00Z`) en `DateTime` UTC.
- Le champ générique `PaginatedData<EtfData>` est désérialisé par json_serializable sans configuration supplémentaire (vérifié à la génération).

---

## 9. Repository (`lib/repositories/etf_repository.dart`)

```dart
class EtfRepository {
  EtfRepository(this._client, this._baseUrl);

  final http.Client _client;
  final String _baseUrl;

  Future<EtfCatalogData> retrieveEtfs() async {
    final json = await _get('/etfs?size=100');
    return EtfCatalogData.fromJson(json as Map<String, dynamic>);
  }

  Future<Object?> _get(String path) async {...}
}
```

`_get` centralise les appels, et les plans 2 et 3 le réutilisent dans la même classe :

| Cas | Résultat |
|---|---|
| 2xx | `jsonDecode(utf8.decode(response.bodyBytes))` |
| Autre statut, corps = liste de `{ error, message }` | `ApiException` avec les `message` |
| Autre statut, corps illisible ou liste vide | `ApiException(['error.unexpected'])` |
| Erreur réseau (`ClientException`, `SocketException`) | `ApiException(['error.unexpected'])` |
| Réponse 2xx mais JSON inattendu (`fromJson` qui lève) | `ApiException(['error.unexpected'])` |

- **`utf8.decode(bodyBytes)` plutôt que `response.body`** : sans `charset` dans l'en-tête `Content-Type`, `response.body` décode en latin-1, ce qui abîmerait les accents.
- Pas de timeout explicite (KISS). Le backend peut mettre quelques secondes à répondre s'il synchronise le catalogue avec Twelve Data (timeout de lecture de 10 s côté backend).

---

## 10. Store et écran

### 10.1 `lib/stores/etf/etf_catalog_state.dart`

```dart
@freezed
abstract class EtfCatalogState with _$EtfCatalogState {
  const factory EtfCatalogState({
    EtfCatalogData? catalog,
    @Default(false) bool isLoading,
    String? errorKey,
  }) = _EtfCatalogState;
}
```

### 10.2 `lib/stores/etf/etf_catalog_store.dart`

`EtfCatalogStore extends Cubit<EtfCatalogState>`, avec une seule méthode `init()` : `isLoading: true, errorKey: null`, appel de `retrieveEtfs()`, puis `catalog` ou `errorKey` (première clé de l'`ApiException`). Le bouton « Réessayer » rappelle `init()`.

### 10.3 Fourniture au niveau de l'app

Le catalogue sert à plusieurs écrans : la liste (ce plan) et le choix des deux ETF à comparer (plan 3). Le store est donc fourni **au-dessus du routeur**, dans `IndiceApp` :

```dart
BlocProvider(
  create: (_) => EtfCatalogStore(getIt<EtfRepository>())..init(),
  child: MaterialApp.router(...),
)
```

- **Création paresseuse** : `lazy` vaut `true` par défaut, et `create` n'est appelé qu'au premier accès ([doc flutter_bloc](https://pub.dev/documentation/flutter_bloc/latest/flutter_bloc/BlocProvider-class.html) : « By default, `create` is called only when the instance is accessed. »). Le catalogue est donc chargé à la première ouverture d'un écran qui le lit, pas au lancement de l'app. `init()` n'a pas besoin de vérifier si le catalogue est déjà chargé.
- Le catalogue n'est plus rechargé ensuite pendant la vie de l'app, ce qui est acceptable puisqu'il change au plus une fois par semaine. Seul « Réessayer », après une erreur, le recharge.
- Règle générale (à ajouter au `CLAUDE.md`, section 11) : **un store par notion ; fourni au niveau de l'app s'il est partagé entre plusieurs écrans, sinon créé par l'écran**. Les stores éphémères, comme le résultat d'une comparaison, restent créés par leur écran.

### 10.4 Widgets (`lib/widgets/`)

| Widget | Paramètres | Affichage |
|---|---|---|
| `card/etf_card.dart` → `EtfCard` | `name`, `ticker`, `exchange`, `currency`, `onTap` (`VoidCallback?`, `null` pour l'instant) | Nom en titre, ticker mis en évidence, `NYSE ARCA · USD` en secondaire |
| `banner/stale_data_banner.dart` → `StaleDataBanner` | `message` (`String`) | Bandeau d'information discret. Réutilisable par le détail et la comparaison (champ `stale` par ETF) |

Les couleurs et styles viennent du thème. Si un style manque, il est ajouté dans `app_theme.dart`, jamais en dur dans le widget.

### 10.5 `lib/utils/date_formatting.dart`

Extension `DateTime.toFrenchDate()` → `15/10/2026` : conversion en heure locale (`toLocal()`), jour et mois sur deux chiffres. Elle servira aussi au plan 3 (dates de la période commune).

### 10.6 `lib/screens/compare/etf_catalog_screen.dart`

`EtfCatalogScreen` remplace `lib/pages/compare_page.dart` (supprimé) dans la branche `/compare`.

- Ne crée pas le store : il lit celui de l'app avec `BlocBuilder<EtfCatalogStore, EtfCatalogState>`.
- `AppBar` titrée « Comparer ».
- Trois états :
  - **chargement** : `CircularProgressIndicator` centré ;
  - **erreur** : message traduit (`errorMessage(errorKey)`) et bouton « Réessayer » → `store.init()` ;
  - **données** : `ListView` avec le bandeau en tête si `stale`, puis une `EtfCard` par ETF.
- Texte du bandeau :
  - avec date : « Le catalogue n'a pas pu être mis à jour. Dernière mise à jour le 07/10/2026. »
  - sans date : « Le catalogue n'a pas pu être mis à jour. »
- Liste vide (catalogue jamais synchronisé et Twelve Data indisponible) : « Aucun ETF disponible pour le moment. »

Les textes sont à relire ensemble.

---

## 11. Documentation

- **`CLAUDE.md` mobile** (commit 🔧) :
  - section *Repositories* : la clé d'erreur est dans `message`, et non dans `error` ;
  - section *Architecture* : ajouter `utils/` (fonctions de formatage et utilitaires sans état) ;
  - section *Stores* : un store par notion, fourni au niveau de l'app (dans `IndiceApp`, au-dessus du routeur) s'il est partagé entre plusieurs écrans, sinon créé par l'écran ;
  - sections *Screens* et *Injection* : `getIt` est aussi lu à la création des stores fournis au niveau de l'app.
- **`README.md`** : remplacer le texte généré par Flutter par les étapes de démarrage (copier `.env.example` en `.env.local`, `build_runner`, lancer le backend).

---

## 12. Tests

Arborescence miroir de `lib/`. Aucun appel réel à l'API. Le faux repository et un constructeur de catalogue de test sont partagés dans `test/fakes/fake_etf_repository.dart` (utilisés par trois fichiers de test).

| Fichier | Contenu |
|---|---|
| `test/repositories/etf_repository_test.dart` | Avec `MockClient` (`package:http/testing.dart`) : URL appelée (`/etfs?size=100`) ; succès avec `fetchedAt` présent et `null` ; caractères accentués ; erreur 500 avec clé ; plusieurs erreurs ; corps illisible ; erreur réseau ; JSON 200 inattendu |
| `test/stores/etf/etf_catalog_store_test.dart` | Faux `EtfRepository` (`implements`) : `init()` passe par `isLoading` puis donne le catalogue ; erreur → `errorKey` ; un second `init()` après une erreur efface `errorKey` |
| `test/widgets/card/etf_card_test.dart` | Nom, ticker, `exchange · currency` ; `onTap` appelé |
| `test/widgets/banner/stale_data_banner_test.dart` | Affiche le message |
| `test/utils/date_formatting_test.dart` | Zéros à gauche ; conversion UTC → heure locale |
| `test/screens/compare/etf_catalog_screen_test.dart` | Écran enveloppé dans un `BlocProvider` dont le store reçoit un faux repository (sans get_it) : chargement, données (cartes + bandeau si `stale`), erreur et « Réessayer », liste vide |
| `test/widget_test.dart` | Faux `EtfRepository` enregistré dans get_it (`setUp` / `tearDown` avec `getIt.reset()`) : ouverture de l'onglet Comparer ; le repository n'est pas appelé tant que l'onglet n'est pas ouvert, et un seul appel après plusieurs allers-retours entre onglets |

Rappel : `flutter test` compile les shaders avec `impellerc`, ce qui peut déclencher une demande d'autorisation macOS.

---

## 13. Découpage en commits

Branche `feat/mobile/etf-catalog` :

1. `🔧 : mobile - document api error keys, shared stores and utils folder` (section 11, `CLAUDE.md`, et ce plan)
2. `✨ : mobile - list etfs in the compare tab` (sections 5 à 10, 12, README)

---

## 14. Critères de fin

- [ ] `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze` (aucun avertissement) et `flutter test` passent.
- [ ] Backend lancé : l'onglet Comparer affiche les 10 ETF triés par nom, sur l'émulateur Android et sur le simulateur iOS.
- [ ] Le catalogue n'est appelé qu'à la première ouverture de l'onglet Comparer, et pas à nouveau lors des allers-retours entre onglets.
- [ ] Backend arrêté : le message d'erreur s'affiche, et « Réessayer » recharge la liste une fois le backend relancé.
- [ ] Aucun calcul de donnée métier côté mobile, ni aucune couleur ou `TextStyle` en dur dans les nouveaux widgets.
- [ ] `.env.local` n'apparaît pas dans `git status`.

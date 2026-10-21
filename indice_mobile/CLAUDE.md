# CLAUDE.md — Indice Mobile

## Contexte

**Indice** est une application mobile pédagogique qui aide les débutants (étudiants, jeunes actifs) à comprendre l'investissement financier, en particulier les **ETF**. Ce projet est l'**application Flutter** : elle affiche les données de l'API REST `../indice-backend`.

Modules fonctionnels : **Apprendre** (ressources pédagogiques), **Comparer** (fiches et comparaison d'ETF), **Construire** (portefeuille fictif, plus tard : **ne rien implémenter pour ce module sans demande explicite**).

Contraintes non négociables :
- **L'application est un afficheur.** Toute la logique métier est dans le backend : l'application affiche ce que l'API renvoie et ne produit aucune donnée métier (pas de calcul de performance, d'écart, de moyenne, de classement…). Si une donnée manque à l'écran, elle est ajoutée côté backend.
- **Aucun conseil en investissement** : libellés factuels et neutres (pas de « meilleur ETF », « à acheter »…).
- Aucune transaction réelle, aucune connexion bancaire ou courtier.

Vocabulaire financier et métier : `../indice-backend/docs/glossaire.md`. Format exact des réponses de l'API : les DTOs de `../indice-backend/src/main/kotlin/com/fisa/indice/<domaine>/dtos/responses/`.

> **Migration en cours** : le code actuel (`lib/pages/`, `lib/models/`, couleurs en dur) ne suit pas encore ce document. Il sera aligné par un refactoring dédié ; tout nouveau code suit d'emblée les règles ci-dessous.

## Stack

| Besoin | Paquet |
|---|---|
| Framework | Flutter (Dart) |
| Gestion d'état (stores) | `flutter_bloc` (Cubit) |
| Models immuables et JSON | `freezed`, `json_serializable` (génération avec `build_runner`) |
| Injection de dépendances | `get_it` |
| Navigation | `go_router` |
| Appels à l'API | `http` |
| Variables d'environnement | `flutter_dotenv` |
| Lecture vidéo | `video_player` |

## Commandes

```bash
flutter pub get                                              # Dépendances
dart run build_runner build --delete-conflicting-outputs     # Génère *.freezed.dart et *.g.dart
flutter run                                                  # Lancer l'app (API backend démarrée)
flutter analyze                                              # Analyse statique (lints)
flutter test                                                 # Tous les tests
```

## Principes généraux

- **KISS** : la solution la plus simple qui répond au besoin. Pas d'abstraction « au cas où ».
- **YAGNI** : n'implémenter que ce qui est demandé. Pas d'écran, de champ, de paramètre ou de couche spéculatifs. Une classe abstraite n'est créée que s'il existe plusieurs implémentations ou un besoin réel de substitution.
- **SOLID** :
  - *S* — une classe = une responsabilité (widget ≠ screen ≠ store ≠ repository).
  - *O* — étendre par composition de widgets plutôt qu'en multipliant les `if`/`switch` dans un `build`.
  - *L* — une implémentation respecte le contrat de son abstraction.
  - *I* — un widget ne reçoit que les paramètres dont il a besoin.
  - *D* — dépendances reçues par le constructeur ; get_it n'est lu qu'aux points d'assemblage (voir Injection).
- **Tell, don't ask** : un widget **signale** une action par un callback (`onFavoriteTap`) ; le screen la transmet au store en appelant sa méthode (`store.toggleFavourite(id)`), et c'est le store qui décide du nouvel état. Le screen ne calcule pas lui-même le nouvel état.
- **DRY raisonné** : factoriser à partir de la 3e duplication réelle, pas avant.
- Respecter les conventions officielles Dart et Flutter ([Effective Dart](https://dart.dev/effective-dart), lints `flutter_lints`) : fichiers en `snake_case`, classes en `UpperCamelCase`, constructeurs `const` dès que possible.
- Code et identifiants en **anglais** ; textes affichés à l'utilisateur en **français**.
- Pas de code mort, pas de `TODO` laissés sans le signaler.

## Façon de travailler

- Lire le code existant avant d'écrire, et s'aligner sur ses conventions.
- Changements petits et ciblés ; ne pas refactorer hors du périmètre demandé (le proposer plutôt).
- **Ne pas ajouter de dépendance** sans l'annoncer et le justifier.
- Lancer `flutter analyze` (aucun avertissement) et `flutter test` avant d'annoncer qu'une tâche est terminée.
- Les fichiers `*.freezed.dart` et `*.g.dart` sont ignorés par Git : les générer avec `build_runner` après un clone, un changement de branche ou toute modification d'une classe `@freezed`. Ne jamais les modifier à la main.
- Ne jamais commiter sans demande. Commits et pull requests : voir `../CLAUDE.md` (scope `mobile`).

## Architecture

Premier niveau : un dossier par **couche**. Second niveau : un dossier par **notion métier** (ou par famille pour les widgets).

```
lib/
├── main.dart
├── injection.dart          # enregistrement get_it (client http, repositories)
├── router.dart             # routes go_router
├── theme/                  # ThemeData : couleurs, TextTheme
├── errors/                 # traduction des clés d'erreur de l'API en messages français
├── data/                   # models des données reçues de l'API, par notion
│   ├── etf/                # etf_data.dart, etf_comparison_data.dart…
│   └── resource/
├── repositories/           # appels à l'API, par notion : etf_repository.dart…
├── stores/                 # états de l'app (Cubit), par notion
│   └── etf/                # etf_comparison_store.dart + etf_comparison_state.dart
├── screens/                # assemblages de widgets, par module : home/, compare/, learn/…
└── widgets/                # composants réutilisables, par famille : button/, card/…
```

- Ne créer un dossier que lorsqu'il a un premier fichier (pas de dossiers vides).
- Flux unique : `Screen → Store → Repository → API`. Aucun saut de couche : un screen n'appelle jamais un repository.
- Un widget ne connaît ni store, ni repository, ni get_it.

## Nommage

| Type | Suffixe | Exemple (fichier → classe) |
|---|---|---|
| Model de données | `Data` | `etf_data.dart` → `EtfData` |
| Repository | `Repository` | `etf_repository.dart` → `EtfRepository` |
| Store | `Store` | `etf_comparison_store.dart` → `EtfComparisonStore` |
| État d'un store | `State` | `etf_comparison_state.dart` → `EtfComparisonState` |
| Screen | `Screen` | `compare_screen.dart` → `CompareScreen` |
| Widget | sa nature | `resource_card.dart` → `ResourceCard`, `module_button.dart` → `ModuleButton` |

## Models de données (`lib/data/`)

- Reflet **fidèle** du JSON renvoyé par l'API : mêmes champs, même nullabilité. Un champ que l'API peut renvoyer à `null` est nullable en Dart, jamais remplacé par une valeur par défaut inventée.
- Annotés `@freezed`, immuables, avec `fromJson`. Chaque fichier déclare ses deux `part`, en reprenant le nom du fichier :

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'etf_data.freezed.dart';
  part 'etf_data.g.dart';

  @freezed
  abstract class EtfData with _$EtfData {
    const factory EtfData({
      required String ticker,
      required String name,
      double? expenseRatio,
    }) = _EtfData;

    factory EtfData.fromJson(Map<String, dynamic> json) => _$EtfDataFromJson(json);
  }
  ```
- `@JsonKey(name: ...)` uniquement si le nom JSON diffère du nom Dart.
- **Aucune logique métier** : ni calcul, ni règle de décision.
- Réponses paginées de l'API (`{ "content": [...], "page", "size", "totalElements", "totalPages" }`) : un model générique `PageData<T>` (`lib/data/common/`), avec `@Freezed(genericArgumentFactories: true)`.
- Si un changement du contrat d'API casse un model, le signaler (le backend fait foi).

## Repositories (`lib/repositories/`)

- Seul endroit qui appelle l'API (paquet `http`). Un repository par notion.
- Reçoivent le `http.Client` et l'URL de base par constructeur, et renvoient des models `Data` (`Future<EtfData>`, `Future<PageData<EtfData>>`). Jamais de `Map` JSON ni de `Response` en sortie.
- Réponse en erreur : le corps de l'API est toujours une **liste** de `{ "error": "error.etfs.etf-not-found", "message": "..." }`. Le repository la convertit en `ApiException` portant les **clés** d'erreur ; une erreur réseau ou un corps illisible donne la clé `error.unexpected`.
- Classe concrète par défaut (cf. YAGNI).

## Stores (`lib/stores/`)

- Un store est un `Cubit<XxxState>` nommé `XxxStore`. Son état est une classe `@freezed` dans un fichier séparé :

  ```dart
  // etf_comparison_state.dart
  part 'etf_comparison_state.freezed.dart';

  @freezed
  abstract class EtfComparisonState with _$EtfComparisonState {
    const factory EtfComparisonState({
      EtfComparisonData? comparison,
      @Default(false) bool isLoading,
      String? errorKey,
    }) = _EtfComparisonState;
  }
  ```

  ```dart
  // etf_comparison_store.dart
  class EtfComparisonStore extends Cubit<EtfComparisonState> {
    EtfComparisonStore(this._etfRepository) : super(const EtfComparisonState());

    final EtfRepository _etfRepository;

    Future<void> compare(String etfA, String etfB) async {
      emit(state.copyWith(isLoading: true, errorKey: null));
      try {
        final comparison = await _etfRepository.compare(etfA, etfB);
        emit(state.copyWith(comparison: comparison, isLoading: false));
      } on ApiException catch (exception) {
        emit(state.copyWith(isLoading: false, errorKey: exception.errorKeys.first));
      }
    }
  }
  ```
- Chaque action utilisateur est une **méthode nommée** du store (`compare`, `toggleFavourite`…), qui fait un `emit(state.copyWith(...))`. `emit` n'est appelé que dans le store.
- Chargement initial dans une méthode `init()`, appelée à la création du store.
- Le store reçoit ses repositories par constructeur (testable), sans lire get_it.
- Getters dérivés (`visibleProducts`, `favouriteCount`) autorisés pour l'**état d'interface** (filtre, sélection, compteur d'affichage), jamais pour produire une donnée financière.
- L'erreur est stockée sous forme de **clé** dans l'état ; le screen la traduit avec `lib/errors/`.

## Screens (`lib/screens/`)

- Assemblent des widgets ; un dossier par module (`home/`, `compare/`, `learn/`, `build/`).
- Créent le store avec `BlocProvider(create: (_) => XxxStore(getIt<XxxRepository>())..init())`, lisent l'état avec `BlocBuilder` / `context.watch`, et relient les callbacks des widgets aux méthodes du store.
- Gèrent les trois cas de l'état : chargement, erreur (message traduit), données.
- Un morceau d'écran réutilisé ou qui a un sens propre est extrait en widget dans `lib/widgets/`.

## Widgets (`lib/widgets/`)

- Composants réutilisables, regroupés par famille : `button/`, `card/`…
- `StatelessWidget` par défaut, constructeur `const`. Un `StatefulWidget` seulement pour un état purement visuel et local (animation, champ de saisie).
- Reçoivent des valeurs prêtes à afficher et des callbacks (`VoidCallback`, `ValueChanged<T>`), rien d'autre.

## Affichage et formatage

- Le **formatage** est permis côté mobile : `0.0712` → `7,12 %`, dates, unités, texte de remplacement pour une valeur `null` (`—`). Il est placé dans des fonctions ou extensions réutilisables, pas dupliqué dans les widgets.
- Tout calcul qui produit une **nouvelle donnée** (écart entre deux ETF, moyenne, rendement…) est interdit : il est demandé au backend.

## Thème

- Couleurs, tailles et styles de texte définis une seule fois dans le `ThemeData` (`lib/theme/`) et lus avec `Theme.of(context)`. Pas de `Color(0x...)` ni de `TextStyle` codés en dur dans un widget.

## Navigation

- **go_router** uniquement : routes déclarées dans `lib/router.dart`, navigation par `context.go(...)` / `context.push(...)`. Pas de `Navigator.push`.
- Barre de navigation principale avec un `StatefulShellRoute`.

## Injection (get_it)

- Le client `http` et les repositories sont enregistrés dans `lib/injection.dart` (`registerLazySingleton`), appelé dans `main()` avant `runApp`.
- `getIt<...>()` n'est lu que dans `injection.dart` et à la création des stores dans les screens.

## Erreurs de l'API

- `lib/errors/` contient une table **clé → message français** (`'error.etfs.etf-not-found': 'Cet ETF est introuvable.'`), avec un message générique pour toute clé inconnue.
- Toute nouvelle clé d'erreur du backend y est ajoutée.

## Configuration (`.env`)

- Les variables d'environnement (URL de l'API…) sont dans `.env.local`, ignoré par Git, déclaré comme asset dans `pubspec.yaml` et lu au démarrage avec `flutter_dotenv`. `.env.example`, versionné, liste toutes les clés sans valeur réelle : chaque développeur le copie en `.env.local`.
- Le `.env.local` est embarqué dans l'application installée, donc lisible par n'importe qui : il ne contient **jamais de secret**.

## Tests

Stratégie à définir. En attendant :
- les tests existants restent verts ;
- `flutter analyze` sans avertissement et `flutter test` avant d'annoncer qu'une tâche est terminée ;
- arborescence de `test/` miroir de `lib/`, fichiers `xxx_test.dart`.

# Plan d'implémentation : comparaison de deux ETF (onglet Comparer)

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Troisième des trois plans du module Comparer : catalogue (fait), détail d'un ETF (fait), **comparaison de deux ETF** (ce plan).

## Avant de coder

1. **Lis le code existant** : `lib/router.dart`, `lib/screens/compare/`, `lib/stores/etf/`, `lib/repositories/etf_repository.dart`, `lib/widgets/chart/price_chart.dart`, `lib/widgets/indicator/`, `lib/errors/error_messages.dart`, `lib/utils/number_formatting.dart`, `test/fakes/`.
2. **Lis le contrat de l'API** dans `../indice-backend` : `EtfComparisonResponseDto`, `ComparedEtfResponseDto`, `PerformanceResponseDto`, `DateRangeResponseDto`, et la section 15 de `docs/plans/plan-implementation-etf-comparison.md` (`pricePoints` à la place de `rebasedPrices`, mergé dans `main` avec la PR #19).
3. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.

---

## 1. Objectif

Comparer deux ETF du catalogue sur leur période commune : deux courbes superposées, les indicateurs de chacun côte à côte et leur corrélation. L'écran **explique et montre**, il ne désigne aucun ETF « meilleur » : c'est l'utilisateur qui se fait un avis.

## 2. Hors périmètre

- Le choix de la période (1 an, 3 ans, 5 ans) : piste `period` du plan backend, plus tard.
- La comparaison de plus de deux ETF, l'inversion A/B, l'enregistrement d'une comparaison.
- Toute phrase comparative (« SPY est plus volatil… ») : le tableau suffit.
- Une limite d'ancienneté des données : la comparaison reste possible avec des données périmées (voir 3).
- Le style définitif : thème existant, ajusté plus tard avec les maquettes.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Accès depuis la liste | Bouton « Comparer deux ETFs » en haut de la liste du catalogue : `context.push('/compare/comparison')`. Les deux sélecteurs sont vides |
| Accès depuis la fiche | Bouton « Comparer cet ETF » sous l'en-tête de la fiche : `context.push('/compare/comparison?etfA=SPY')`. L'ETF A est **verrouillé** (sélecteur désactivé) : le retour ramène à sa fiche, ce qui resterait incohérent s'il pouvait changer |
| Route | `/compare/comparison`, route enfant de `/compare` (barre de navigation visible), paramètre facultatif `etfA` |
| Sélecteurs | Deux `SelectField<String>`, « Premier ETF » et « Second ETF ». Chacun propose le catalogue **sans l'ETF choisi dans l'autre**. Désactivés tant que le catalogue charge |
| Appel à l'API | Automatique dès que les deux ETF sont choisis, et à chaque changement de l'un d'eux. Pas de bouton « Comparer » |
| Stores | `EtfComparisonStore`, créé par l'écran. La liste des sélecteurs vient d'`EtfCatalogStore`, déjà fourni au niveau de l'app |
| Courbe | Deux séries superposées : la **variation en % depuis le début de la période commune** (les deux partent de 0 %), données par l'API. Fenêtre initiale sur la dernière année, défilement vers le passé, comme sur la fiche. Info-bulle (appui long) : la date, puis le cours et la variation de chaque ETF |
| Couleurs des courbes | ETF A en `colorScheme.primary`, ETF B en `colorScheme.secondary`, avec une légende. Jamais de vert ni de rouge, qui suggéreraient un jugement |
| Indicateurs | Tableau « indicateur × ETF » : rendement total, rendement annualisé, volatilité, ratio rendement/risque, perte maximale. Une bulle « i » par ligne. Rendements en vert ou rouge selon leur signe, comme sur la fiche. Rien d'autre ne met une colonne en avant (ni gras, ni icône) |
| Période et corrélation | « Comparaison du 20/10/2021 au 19/10/2026 » sous les sélecteurs, avec sa bulle. La corrélation sous le tableau, avec sa bulle |
| Données périmées | Comparaison autorisée. Un bandeau par ETF concerné |
| Erreurs | Message traduit sous les sélecteurs, avec le ticker en cause pour les erreurs 422. « Réessayer » seulement pour une erreur inattendue ou réseau |

## 4. Contrat de l'API

### 4.1 Succès : `GET /api/etfs/compare?etfA=SPY&etfB=QQQ`

```json
{
  "commonPeriod": { "startDate": "2021-10-20", "endDate": "2026-10-19" },
  "correlation": 0.9312,
  "etfA": {
    "ticker": "SPY",
    "exchange": "NYSE",
    "name": "State Street SPDR S&P 500 ETF Trust",
    "currency": "USD",
    "fetchedAt": "2026-10-20T08:00:00Z",
    "stale": false,
    "performance": {
      "totalReturn": 0.8123,
      "annualizedReturn": 0.1263,
      "volatility": 0.1712,
      "returnToRiskRatio": 0.7377,
      "maxDrawdown": { "value": -0.2450, "peakDate": "2022-01-03", "troughDate": "2022-10-12" }
    },
    "pricePoints": [
      { "date": "2021-10-20", "close": 450.00, "changeSinceStart": 0.0 },
      { "date": "2021-10-21", "close": 453.92, "changeSinceStart": 0.0087 }
    ]
  },
  "etfB": { "…": "même structure que etfA" }
}
```

- Nullables : `correlation`, `fetchedAt`, `annualizedReturn`, `volatility`, `returnToRiskRatio`. `totalReturn` et `maxDrawdown` sont toujours présents.
- Les deux séries ont exactement les mêmes dates (période commune).

### 4.2 Erreurs

| Statut | Clé (`message`) | Message affiché |
|---|---|---|
| 422 | `error.etfs.etf-a-insufficient-data` | Comparaison impossible : {etfA} n'a pas assez d'historique (au moins un an est nécessaire). |
| 422 | `error.etfs.etf-b-insufficient-data` | Comparaison impossible : {etfB} n'a pas assez d'historique (au moins un an est nécessaire). |
| 422 | `error.etfs.etfs-insufficient-data` | Comparaison impossible : {etfA} et {etfB} n'ont pas assez d'historique en commun (au moins un an est nécessaire). |
| 400 | `error.etfs.same-etf-comparison` | Choisis deux ETF différents. |
| 400 | `error.request.missing-parameter` | Choisis deux ETF pour les comparer. |
| 404 / 400 | `error.etfs.etf-not-found`, `error.etfs.invalid-ticker` | Déjà traduites (fiche détail) |

Les deux erreurs 400 ne peuvent pas arriver depuis l'interface (sélecteurs exclusifs, appel seulement avec deux ETF) : leurs clés sont traduites quand même.

---

## 5. Navigation (`lib/router.dart`)

Dans les routes enfants de `/compare`, à côté de `etf/:ticker` :

```dart
GoRoute(
  path: 'comparison',
  builder: (_, state) =>
      EtfComparisonScreen(etfA: state.uri.queryParameters['etfA']),
),
```

- `EtfCatalogScreen` : un `FilledButton` « Comparer deux ETFs » en tête de liste, au-dessus du bandeau et des cartes.
- `EtfDetailScreen` : un `FilledButton` « Comparer cet ETF » sous l'en-tête (nom, ticker), avant le bloc des données de marché. Il s'affiche aussi sans données de marché (l'API renverra alors l'erreur « pas assez d'historique »).

## 6. Données (`lib/models/etf/`)

Un fichier par classe, reflet fidèle des DTOs. On réutilise `MaxDrawdownData` et `PricePointData` de la fiche.

| Fichier | Classe | Champs |
|---|---|---|
| `etf_comparison_data.dart` | `EtfComparisonData` | `DateRangeData commonPeriod`, `double? correlation`, `ComparedEtfData etfA`, `ComparedEtfData etfB` |
| `compared_etf_data.dart` | `ComparedEtfData` | `ticker`, `exchange`, `name`, `currency`, `DateTime? fetchedAt`, `bool stale`, `PerformanceData performance`, `List<PricePointData> pricePoints` |
| `performance_data.dart` | `PerformanceData` | `double totalReturn`, `double? annualizedReturn`, `double? volatility`, `double? returnToRiskRatio`, `MaxDrawdownData maxDrawdown` |
| `date_range_data.dart` | `DateRangeData` | `DateTime startDate`, `DateTime endDate` |

## 7. Repository (`lib/repositories/etf_repository.dart`)

```dart
Future<EtfComparisonData> compare(String etfA, String etfB) async {
  final response = await http.get<Map<String, dynamic>>(
    '/etfs/compare',
    queryParameters: {'etfA': etfA, 'etfB': etfB},
  );
  return EtfComparisonData.fromJson(response.data!);
}
```

## 8. Store (`lib/stores/etf/`)

- `etf_comparison_state.dart` : `EtfComparisonState({String? etfA, String? etfB, EtfComparisonData? comparison, @Default(false) bool isLoading, String? errorKey})`.
- `etf_comparison_store.dart` : `EtfComparisonStore(this._etfRepository, {String? etfA})`, état initial avec cet `etfA`. Pas de `init()` : rien à charger tant que les deux ETF ne sont pas choisis.
  - `selectEtfA(String ticker)` et `selectEtfB(String ticker)` : enregistrent le choix, effacent `comparison` et `errorKey`, puis appellent `_compare()` si les deux ETF sont choisis.
  - `retry()` : relance `_compare()` avec les deux ETF actuels.
  - `_compare()` : `isLoading`, puis la comparaison ou la clé d'erreur (`unexpectedErrorKey` à défaut), sur le modèle des autres stores. **Réponse obsolète ignorée** : si la sélection a changé pendant l'appel, la réponse ne remplace pas l'état (sinon une réponse lente sur l'ancienne paire écraserait la nouvelle).
- Création dans l'écran : `BlocProvider(create: (_) => EtfComparisonStore(getIt<EtfRepository>(), etfA: etfA))`.

## 9. Widgets

### 9.1 `PriceChart` (`lib/widgets/chart/price_chart.dart`), étendu à plusieurs séries

```dart
const PriceChart({
  super.key,
  required this.series,        // List<({String label, List<({DateTime date, double value})> points})>
  required this.tooltipLabel,  // String Function(int index)
  required this.axisLabel,     // String Function(double value)
});
```

- Une courbe par série. Couleurs prises dans le thème, dans l'ordre : `primary`, puis `secondary`.
- **Légende** sous la courbe (pastille de couleur et `label`), affichée seulement s'il y a plus d'une série.
- Les séries partagent les mêmes dates : l'abscisse reste l'index du point, les années de l'axe horizontal viennent de la première série, et la fenêtre initiale se calcule sur sa longueur (inchangé).
- Une seule info-bulle pour toutes les séries : le texte de `tooltipLabel(index)` sur la première, rien sur les autres.
- `axisLabel` : libellé de l'axe vertical. La fiche passe un prix sans décimale (comportement actuel), la comparaison un pourcentage sans décimale.
- La fiche passe une seule série (`label` : le ticker, légende masquée) : affichage inchangé.

### 9.2 Nouveaux widgets

| Fichier | Widget | Rôle |
|---|---|---|
| `field/select_field.dart` | `SelectField<T>` | Enveloppe `DropdownButtonFormField<T>` : `label`, `options` (`List<({T value, String label})>`), `value`, `onChanged` (`null` pour désactiver). Libellés des options sur une ligne, avec « … » s'ils sont trop longs. Générique, sans notion d'ETF |
| `indicator/comparison_table.dart` | `ComparisonTable` | Tableau : une ligne d'en-têtes (`columns`, les tickers), puis une ligne par indicateur (`rows` : `label`, `infoText`, et une valeur par colonne avec son `ValueTrend`). Bulle « i » à côté de chaque libellé. Valeurs centrées, même style dans chaque colonne |

### 9.3 Textes des bulles

Repris du §9.1 du plan backend de la comparaison, neutres :

| Indicateur | Texte |
|---|---|
| Période commune | Les indicateurs sont calculés sur les dates où les deux ETF ont un cours, pour les comparer sur la même période. |
| Courbe | Cours de clôture ajustés des dividendes réinvestis. Les pourcentages indiquent la variation de chaque ETF depuis le JJ/MM/AAAA, début de la période commune : les deux courbes partent de 0 %. |
| Rendement total | Gain ou perte sur toute la période, dividendes réinvestis. |
| Rendement annualisé | Rendement moyen par an sur la période. Il permet de comparer des durées différentes. |
| Volatilité | Ampleur habituelle des variations du prix sur un an. Plus elle est élevée, plus le prix bouge fort, à la hausse comme à la baisse. |
| Ratio rendement/risque | Rendement obtenu pour une unité de volatilité. Il ne dit pas quel ETF choisir : chacun juge selon sa tolérance aux variations. |
| Perte maximale | Plus forte baisse entre un sommet et le creux qui a suivi. Elle montre ce qu'un investisseur aurait pu perdre au pire moment. |
| Corrélation | Entre −1 et 1. Proche de 1 : les deux ETF montent et baissent souvent les mêmes jours, et se protègent peu l'un l'autre. Proche de 0 : leurs mouvements sont peu liés. |

## 10. Écran (`lib/screens/compare/etf_comparison_screen.dart`)

`EtfComparisonScreen({String? etfA})` crée son store, lit `EtfCatalogStore` pour les options. `AppBar` « Comparer deux ETFs ». Contenu dans une `ListView` :

1. **Sélecteurs** : « Premier ETF » (désactivé si `etfA` vient de la fiche) et « Second ETF ». Options : les ETF du catalogue sans celui choisi dans l'autre sélecteur, libellés « SPY · SPDR S&P 500 ETF Trust ». Catalogue en erreur : son message et « Réessayer » (`EtfCatalogStore.init`).
2. Selon l'état :
   - un des deux ETF manque : « Choisis deux ETF pour les comparer. » ;
   - chargement : `CircularProgressIndicator` ;
   - erreur : `errorMessage(errorKey, params: {'etfA': …, 'etfB': …})`, et « Réessayer » (`retry()`) seulement si `errorKey == unexpectedErrorKey` ;
   - comparaison : blocs 3 à 8.
3. « Comparaison du 20/10/2021 au 19/10/2026 » avec sa bulle.
4. Un `StaleDataBanner` par ETF dont `stale` vaut `true` : « Les données de SPY n'ont pas pu être mises à jour. Dernière mise à jour le 20/10/2026. » (sans la date si `fetchedAt` est `null`).
5. **Courbe** : titre « Évolution » avec sa bulle, `PriceChart` avec deux séries (`label` : ticker, `value` : `changeSinceStart`), axe en pourcentage. Info-bulle :
   ```
   12/03/2024
   SPY · 512,40 USD · +13,87 %
   QQQ · 438,20 USD · +21,05 %
   ```
   Moins de 2 points : « Aucun historique de cours disponible pour le moment. » à la place.
6. **Indicateurs** : `ComparisonTable`, colonnes SPY et QQQ.
   - Rendement total, rendement annualisé : pourcentages signés, colorés selon leur signe.
   - Volatilité : pourcentage sans signe.
   - Ratio rendement/risque : nombre à 2 décimales.
   - Perte maximale : pourcentage signé, non coloré.
   - Valeur `null` : « — ».
7. **Corrélation** : `IndicatorTile` « Corrélation », nombre à 2 décimales ou « — ».
8. Rappel : « Les performances passées ne préjugent pas des performances futures. »

## 11. Formatage et erreurs

- `lib/utils/number_formatting.dart` :
  - `toFrenchDecimal()` : `0.7377` → « 0,74 », `-0.12` → « -0,12 », `null` → « — » ;
  - `toFrenchPercent()` et `toFrenchSignedPercent()` reçoivent un paramètre facultatif `fractionDigits` (2 par défaut), pour l'axe vertical en pourcentage sans décimale (« +50 % »).
- `lib/errors/error_messages.dart` :
  - `errorMessage(String key, {Map<String, String> params = const {}})` remplace chaque `{nom}` du message par sa valeur. Sans paramètre, le comportement ne change pas ;
  - ajout des cinq clés de la section 4.2.

---

## 12. Tests

Arborescence miroir de `lib/`. Aucun appel réel à l'API. `test/fakes/fake_etf_repository.dart` : paramètre nommé optionnel `onCompare` et comparaison de test `buildComparison(...)`.

| Fichier | Contenu |
|---|---|
| `test/repositories/etf_repository_test.dart` | `compare` : URL appelée (`/etfs/compare?etfA=SPY&etfB=QQQ`) ; parsing complet ; champs `null` ; une 422 remonte en `DioException` |
| `test/stores/etf/etf_comparison_store_test.dart` | ETF A initial ; un seul ETF choisi : aucun appel ; deux ETF : chargement puis comparaison ; changement d'un ETF : nouvel appel, ancien résultat effacé ; réponse obsolète ignorée ; clé d'erreur de l'API ; `error.unexpected` sinon ; `retry()` |
| `test/utils/number_formatting_test.dart` | `toFrenchDecimal` ; `fractionDigits` |
| `test/errors/error_messages_test.dart` | Remplacement des paramètres ; clé sans paramètre inchangée ; clé inconnue |
| `test/widgets/field/select_field_test.dart` | Options affichées ; `onChanged` appelé ; désactivé si `onChanged` est `null` |
| `test/widgets/indicator/comparison_table_test.dart` | En-têtes, libellés, valeurs ; couleurs selon `ValueTrend` |
| `test/widgets/chart/price_chart_test.dart` | Tests existants adaptés ; deux séries : deux courbes et une légende ; une série : pas de légende |
| `test/screens/compare/etf_comparison_screen_test.dart` | Sélecteurs vides depuis la liste ; ETF A verrouillé depuis la fiche ; options sans l'ETF choisi en face ; message avant le choix ; chargement ; comparaison complète (période, courbe, tableau, corrélation) ; bandeau `stale` ; erreur 422 avec le ticker ; erreur inattendue et « Réessayer » |
| `test/screens/compare/etf_catalog_screen_test.dart`, `etf_detail_screen_test.dart` | Présence des boutons |
| `test/widget_test.dart` | Liste → « Comparer deux ETFs » → écran de comparaison ; fiche → « Comparer cet ETF » → ETF A verrouillé |

Rappel : `flutter test` compile les shaders avec `impellerc`, ce qui peut déclencher une demande d'autorisation macOS.

---

## 13. Découpage en commits

Branche `feat/mobile/etf-comparison`, depuis `main` (le changement backend y est déjà, PR #19) :

- `✨ : mobile - compare two etfs` (ce plan, sections 5 à 12)

---

## 14. Critères de fin

- [ ] `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze` (aucun avertissement) et `flutter test` passent.
- [ ] Backend lancé depuis `main` : comparaison SPY / QQQ depuis la liste et depuis la fiche de SPY (ETF A verrouillé).
- [ ] Changer un ETF relance la comparaison ; un ETF choisi n'apparaît pas dans l'autre sélecteur.
- [ ] Courbe : deux séries partant de 0 %, légende, défilement, info-bulle avec les deux ETF.
- [ ] Aucun élément ne désigne un ETF « meilleur » ; aucune phrase comparative ; aucun calcul de donnée métier côté mobile.
- [ ] Aucune couleur ni `TextStyle` en dur dans les nouveaux widgets.

---

## 15. Ajustements pendant le développement

| Sujet | Plan | Code livré | Raison |
|---|---|---|---|
| `SelectField` et valeur choisie | Non précisé | Le champ reçoit une clé liée à la valeur choisie, et n'affiche la valeur que si elle fait partie des options. Pastille facultative (`leading`) en préfixe | `DropdownButtonFormField` ne lit sa valeur qu'à sa création (`initialValue`, le paramètre `value` est déprécié) et refuse une valeur absente de ses options : sans cela, l'ETF A verrouillé n'apparaîtrait pas une fois le catalogue chargé. Un sélecteur en panneau du bas (*bottom sheet*) a été essayé puis écarté par l'utilisateur |
| Titres de section | Non prévu | Widget privé `_SectionTitle` dupliqué depuis la fiche détail | Deuxième utilisation seulement : factorisation à la troisième (DRY raisonné du `CLAUDE.md`) |
| Série de la fiche | `label` : le ticker | Idem, `_MarketDataView` reçoit le ticker | La légende est masquée avec une seule série, mais le libellé reste juste |
| Espaces insécables | Non prévu | `'\u00A0'` écrit en toutes lettres dans le code et les tests (au lieu du caractère invisible) | Lisibilité : le caractère invisible s'était glissé dans `number_formatting.dart` et deux tests de la fiche |
| Design de l'écran | Structure seule | Une couleur par ETF reprise partout (pastille dans le sélecteur, courbe et légende, en-tête du tableau) ; sélecteurs regroupés dans une carte avec un badge « VS » ; blocs « Évolution », « Indicateurs » et « Corrélation » en cartes ; état vide et erreurs avec une icône ; corrélation en grand avec une jauge `CorrelationGauge` de −1 à 1 (marqueur placé directement à la valeur) | Demande après les premiers essais : écran jugé trop banal |
| Couleur de l'ETF B | `colorScheme.secondary` | `colorScheme.secondary` (vert clair, nuance du vert principal) | Essayé en `tertiary` (bleu-vert) pour mieux distinguer les courbes, puis gardé en `secondary` à la demande de l'utilisateur. `PriceChart` et `ComparisonTable` reçoivent la couleur de chaque série ou colonne, choisie par l'écran |


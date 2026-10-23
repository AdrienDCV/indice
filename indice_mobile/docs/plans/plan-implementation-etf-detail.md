# Plan d'implémentation : détail d'un ETF (onglet Comparer)

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.
> Deuxième des trois plans du module Comparer : catalogue (fait), **détail d'un ETF** (ce plan), puis comparaison de deux ETF.

## Avant de coder

1. **Lis le code existant** : `lib/router.dart`, `lib/screens/compare/etf_catalog_screen.dart`, `lib/stores/etf/`, `lib/repositories/etf_repository.dart`, `lib/widgets/`, `lib/utils/date_formatting.dart`, `test/fakes/`.
2. **Lis le contrat de l'API** dans `../indice-backend` : `EtfDetailResponseDto`, `MarketDataResponseDto` et ses sous-DTOs, et la section 14 de `docs/plans/plan-implementation-etf-detail.md` (série `pricePoints`, ajoutée par la PR backend `feat/backend/etf-detail-chart`).
3. **Vérifie l'API de `fl_chart` 1.3.0** pour le défilement (section 9.2) avant d'écrire le widget de courbe.
4. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.

---

## 1. Objectif

Un appui sur une carte du catalogue ouvre la **fiche d'un ETF** : son identité, une **courbe d'évolution** de son cours sur environ 5 ans, et ses indicateurs de performance et de risque, chacun accompagné d'une bulle d'information pédagogique.

## 2. Hors périmètre

- La comparaison de deux ETF (plan 3).
- Le zoom par pincement et le choix de la période (1 mois, 1 an, 5 ans) : à envisager après les premiers essais de la courbe.
- L'adaptation de l'axe vertical à la fenêtre visible : la première version garde l'échelle de tout l'historique (voir 9.2).
- Le pull-to-refresh, les favoris.
- Le style définitif : on utilise le thème existant, ajusté plus tard avec les maquettes.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| Accès | Appui sur une `EtfCard` du catalogue : `context.push('/compare/etf/<ticker>')` |
| Route | `/compare/etf/:ticker`, route enfant de `/compare` dans la branche Comparer : la barre de navigation reste visible, le retour ramène à la liste. Seul le ticker est transmis (pas d'`extra`) |
| Store | `EtfDetailStore`, **créé par l'écran** : la fiche ne sert à aucun autre écran. `EtfCatalogStore` n'est pas modifié |
| Repository | `EtfRepository.retrieveEtf(ticker)`, dans le repository existant |
| Courbe | Clôtures ajustées en dollars, un point par jour de bourse, sur tout l'historique. Fenêtre initiale sur la dernière année, défilement horizontal vers le passé, sans zoom. Info-bulle au toucher : date, cours et variation depuis le début de l'historique, **fournie par l'API** |
| Bibliothèque | `fl_chart` (voir 9.1) |
| Bulles « i » | Un `InfoTooltipButton` par indicateur, qui ouvre une boîte de dialogue au texte neutre. Réutilisable par la comparaison |
| Formatage | Nouvelle extension `NumberFormatting` dans `lib/utils/number_formatting.dart`, sans `intl` |
| Erreurs | Ajout de `error.etfs.etf-not-found` et `error.etfs.invalid-ticker`. `_ErrorView` du catalogue extrait en `ErrorView` réutilisable |

## 4. Contrat de l'API

### 4.1 Succès : `GET /api/etfs/{ticker}`

```json
{
  "ticker": "SPY",
  "exchange": "NYSE",
  "name": "State Street SPDR S&P 500 ETF Trust",
  "currency": "USD",
  "marketData": {
    "lastClose": 766.48,
    "lastCloseDate": "2026-10-19",
    "historyStartDate": "2021-10-12",
    "returns": { "oneYear": 0.142, "threeYears": 0.51, "fiveYears": 0.88, "fiveYearsAnnualized": 0.135 },
    "volatilityOneYear": 0.161,
    "maxDrawdown": { "value": -0.245, "peakDate": "2022-01-03", "troughDate": "2022-10-12" },
    "fiftyTwoWeekRange": { "low": 629.28, "high": 781.62, "position": 0.9 },
    "pricePoints": [
      { "date": "2021-10-12", "close": 450.00, "changeSinceStart": 0.0 },
      { "date": "2024-03-12", "close": 512.40, "changeSinceStart": 0.1387 }
    ]
  },
  "fetchedAt": "2026-10-20T09:00:00Z",
  "stale": false
}
```

- Nullables : `marketData`, `fetchedAt` ; dans `marketData` : chaque rendement, `volatilityOneYear`, `maxDrawdown`, `fiftyTwoWeekRange`. `pricePoints` est toujours présent quand `marketData` l'est.
- Taux en **fractions** (`0.142` = 14,2 %). Environ 1 260 points dans `pricePoints` (environ 75 Ko).

### 4.2 Erreurs

| Statut | Clé (`message`) | Message affiché |
|---|---|---|
| 404 | `error.etfs.etf-not-found` | Cet ETF est introuvable. |
| 400 | `error.etfs.invalid-ticker` | Ce code d'ETF n'est pas valide. |

---

## 5. Navigation (`lib/router.dart`)

```dart
GoRoute(
  path: '/compare',
  builder: (_, _) => const EtfCatalogScreen(),
  routes: [
    GoRoute(
      path: 'etf/:ticker',
      builder: (_, state) =>
          EtfDetailScreen(ticker: state.pathParameters['ticker']!),
    ),
  ],
),
```

Dans `EtfCatalogScreen`, chaque carte reçoit `onTap: () => context.push('/compare/etf/${etf.ticker}')`.

## 6. Données (`lib/models/etf/`)

Un fichier par classe, reflet fidèle des DTOs. `BigDecimal` → `double`, `LocalDate` et `Instant` → `DateTime`.

| Fichier | Classe | Champs |
|---|---|---|
| `etf_detail_data.dart` | `EtfDetailData` | `ticker`, `exchange`, `name`, `currency`, `MarketData? marketData`, `DateTime? fetchedAt`, `bool stale` |
| `market_data.dart` | `MarketData` | `double lastClose`, `DateTime lastCloseDate`, `DateTime historyStartDate`, `ReturnsData returns`, `double? volatilityOneYear`, `MaxDrawdownData? maxDrawdown`, `PriceRangeData? fiftyTwoWeekRange`, `List<PricePointData> pricePoints` |
| `returns_data.dart` | `ReturnsData` | `double? oneYear`, `threeYears`, `fiveYears`, `fiveYearsAnnualized` |
| `max_drawdown_data.dart` | `MaxDrawdownData` | `double value`, `DateTime peakDate`, `DateTime troughDate` |
| `price_range_data.dart` | `PriceRangeData` | `double low`, `double high`, `double position` |
| `price_point_data.dart` | `PricePointData` | `DateTime date`, `double close`, `double changeSinceStart` |

`MarketData` garde ce nom : il finit déjà par « Data » (pas de `MarketDataData`).

## 7. Repository (`lib/repositories/etf_repository.dart`)

```dart
Future<EtfDetailData> retrieveEtf(String ticker) async {
  final response = await http.get<Map<String, dynamic>>(
    '/etfs/${Uri.encodeComponent(ticker)}',
  );
  return EtfDetailData.fromJson(response.data!);
}
```

Le ticker vient de l'URL : `encodeComponent` évite qu'un ticker mal formé change le chemin appelé. Le backend le normalise et renvoie 400 s'il est invalide.

## 8. Store (`lib/stores/etf/`)

- `etf_detail_state.dart` : `EtfDetailState({EtfDetailData? etf, @Default(false) bool isLoading, String? errorKey})`.
- `etf_detail_store.dart` : `EtfDetailStore(this._etfRepository, this._ticker)`, méthode `init()` sur le modèle d'`EtfCatalogStore` (`isLoading`, puis la fiche ou la clé d'erreur, `unexpectedErrorKey` à défaut).
- Création dans l'écran : `BlocProvider(create: (_) => EtfDetailStore(getIt<EtfRepository>(), ticker)..init())`.

## 9. Courbe

### 9.1 Dépendance : `fl_chart: ^1.3.0`

Vérifiée sur pub.dev le 23/10/2026 : éditeur vérifié (flchart.dev), licence MIT, 160/160 points pub.dev, environ 7 200 likes et 2 millions de téléchargements, dépendances `equatable` et `vector_math`, Dart 3.6 minimum (le projet est en `^3.13.3`). La 1.3.0 a été publiée le 21/10/2026 : en cas de souci, revenir à la 1.2.0.

À ajouter dans le tableau *Stack* du `CLAUDE.md` mobile (« Graphiques | `fl_chart` »).

### 9.2 Widget `PriceChart` (`lib/widgets/chart/price_chart.dart`)

Générique, pour être repris par la comparaison : il ne connaît ni les models ni la notion d'ETF.

```dart
const PriceChart({
  super.key,
  required this.points,        // List<({DateTime date, double value})>
  required this.tooltipLabel,  // String Function(int index)
});
```

- `LineChart` d'une seule série, sans points visibles, couleur `colorScheme.primary`, hauteur fixe (environ 220).
- Abscisse : l'**index** du point (les jours sans cotation ne laissent pas de trou). Libellés de l'axe horizontal : l'année, sur le premier point de chaque année. Axe vertical : valeurs sans décimale.
- **Défilement** : `FlTransformationConfig` (disponible depuis fl_chart 0.70), axe horizontal, `panEnabled: true`, `scaleEnabled: false`, et un `TransformationController` initialisé pour afficher la **dernière année** (agrandissement d'environ `nombre de points / 252`, cadré sur la fin). Avec 252 points ou moins (moins d'un an d'historique), pas d'agrandissement : la courbe affiche tout l'historique, sans défilement. Ce réglage de la fenêtre est un état d'affichage, pas une donnée métier. `PriceChart` est donc un `StatefulWidget` (il possède le contrôleur). **À vérifier** dans l'API de la 1.3.0 avant de coder ; si la fenêtre initiale ne peut pas être réglée ainsi, revenir vers l'utilisateur avec une alternative.
- Info-bulle au toucher : le texte renvoyé par `tooltipLabel(index)`.
- Limite connue : l'échelle verticale couvre tout l'historique, la dernière année peut donc paraître « aplatie ». À retravailler après les premiers essais.

Dans l'écran : `points` = `pricePoints` (`date`, `close`), `tooltipLabel` = `'12/03/2024 · 512,40 USD · +13,87 % depuis le 12/10/2021'` (date du point, `close.toFrenchPrice(currency)`, `changeSinceStart.toFrenchSignedPercent()`, `historyStartDate.toFrenchDate()`).

## 10. Écran (`lib/screens/compare/etf_detail_screen.dart`)

`EtfDetailScreen({required String ticker})` crée son store. `AppBar` titré avec le ticker (connu dès l'ouverture). Trois états : chargement, erreur (`ErrorView` avec « Réessayer » qui rappelle `init()`), données.

Contenu, de haut en bas, dans une `ListView` :

1. **En-tête** : nom ; « SPY · NYSE · USD ».
2. **Bandeau** `StaleDataBanner` si `stale` et `marketData` présent : « Données au 19/10/2026, mise à jour impossible. » (date de `lastCloseDate`).
3. Si `marketData` est `null` : « Aucun historique de cours disponible pour le moment. » à la place des blocs 4 à 10. Le mobile ne peut pas savoir si l'ETF n'a pas d'historique ou si Twelve Data est indisponible (la réponse est la même) : le texte couvre les deux cas.
4. **Dernier cours** : « 766,48 USD au 19/10/2026 ».
5. **Courbe** (`PriceChart`) avec sa bulle « i ». Avec moins de 2 points dans `pricePoints`, le même texte qu'au bloc 3 la remplace : une courbe d'un seul point ne montre rien.
6. **Rendements** : 1 an, 3 ans, 5 ans, 5 ans annualisé (pourcentages signés).
7. **Volatilité sur 1 an** (pourcentage sans signe).
8. **Perte maximale sur 5 ans** : valeur, et « du 03/01/2022 au 12/10/2022 ».
9. **Fourchette sur 52 semaines** : plus bas, plus haut, et la barre `PriceRangeBar`.
10. Si au moins un indicateur vaut `null` : « Historique disponible depuis le 12/10/2021. »
11. **Rappel** : « Les performances passées ne préjugent pas des performances futures. »

Une valeur `null` s'affiche « — ».

## 11. Widgets (`lib/widgets/`)

| Fichier | Widget | Rôle |
|---|---|---|
| `chart/price_chart.dart` | `PriceChart` | Section 9.2 |
| `info/info_tooltip_button.dart` | `InfoTooltipButton(title, text)` | Icône « i » qui ouvre une `AlertDialog` (titre, texte, bouton « Fermer ») |
| `indicator/indicator_tile.dart` | `IndicatorTile(label, value, infoTitle, infoText, {detail})` | Une ligne : libellé, bulle « i », valeur formatée, et une précision facultative (dates de la perte maximale) |
| `indicator/price_range_bar.dart` | `PriceRangeBar(low, high, position)` | Barre horizontale avec un curseur placé à `position` (0 à 1, fournie par l'API), bornes affichées sous la barre |
| `error/error_view.dart` | `ErrorView(message, onRetry)` | Extrait de `_ErrorView` (`etf_catalog_screen.dart`), sans changement de comportement |

Couleurs et styles lus dans `Theme.of(context)`.

### 11.1 Textes des bulles

Adaptés du §9.1 du plan backend de la comparaison, neutres et sans jugement :

| Indicateur | Texte |
|---|---|
| Courbe | Cours de clôture de chaque jour de bourse, ajustés des dividendes réinvestis : les cours passés sont corrigés pour rester comparables à celui d'aujourd'hui, ils peuvent donc différer du prix affiché à l'époque. Le pourcentage indique la variation depuis le JJ/MM/AAAA, début de l'historique. |
| Rendement (1, 3, 5 ans) | Gain ou perte sur la période, dividendes réinvestis. |
| Rendement annualisé | Rendement moyen par an sur 5 ans. Il permet de comparer des durées différentes. |
| Volatilité | Ampleur habituelle des variations du prix sur un an. Plus elle est élevée, plus le prix bouge fort, à la hausse comme à la baisse. |
| Perte maximale | Plus forte baisse entre un sommet et le creux qui a suivi, sur 5 ans. Elle montre ce qu'un investisseur aurait pu perdre au pire moment. |
| Fourchette sur 52 semaines | Plus bas et plus haut cours de clôture de la dernière année. Le curseur situe le dernier cours dans cette fourchette. |

## 12. Formatage (`lib/utils/number_formatting.dart`)

Extension `NumberFormatting on double?`, sur le modèle de `DateFormatting`. Chaque méthode renvoie « — » pour `null`. Virgule décimale, espace insécable avant `%` et entre les milliers.

| Méthode | Exemples |
|---|---|
| `toFrenchPercent()` | `0.161` → « 16,10 % » |
| `toFrenchSignedPercent()` | `0.142` → « +14,20 % » ; `-0.245` → « -24,50 % » ; `0` → « 0,00 % » |
| `toFrenchPrice(String currency)` | `766.48` → « 766,48 USD » ; `1234.5` → « 1 234,50 USD » |

## 13. Erreurs (`lib/errors/error_messages.dart`)

Ajouter les deux clés de la section 4.2.

---

## 14. Tests

Arborescence miroir de `lib/`. Aucun appel réel à l'API. `test/fakes/fake_etf_repository.dart` : ajout d'un paramètre nommé optionnel `onRetrieveEtf` et d'une fiche de test `buildEtfDetail(...)` ; les tests existants ne changent pas.

| Fichier | Contenu |
|---|---|
| `test/repositories/etf_repository_test.dart` | `retrieveEtf` : chemin appelé (`/etfs/SPY`) ; parsing complet ; `marketData` `null` ; indicateurs `null` ; une 404 remonte en `DioException` |
| `test/stores/etf/etf_detail_store_test.dart` | `init()` : chargement puis fiche ; clé d'erreur de l'API ; `error.unexpected` sinon ; ticker transmis au repository |
| `test/utils/number_formatting_test.dart` | Les exemples de la section 12, arrondis, `null` |
| `test/widgets/chart/price_chart_test.dart` | S'affiche avec une série de plus d'un an et avec moins d'un an ; libellé d'info-bulle demandé pour l'index touché |
| `test/widgets/info/info_tooltip_button_test.dart` | L'appui ouvre la boîte de dialogue, « Fermer » la referme |
| `test/widgets/indicator/indicator_tile_test.dart` | Libellé, valeur, précision facultative |
| `test/widgets/indicator/price_range_bar_test.dart` | Bornes affichées |
| `test/widgets/error/error_view_test.dart` | Message ; « Réessayer » appelle le callback |
| `test/screens/compare/etf_detail_screen_test.dart` | Chargement ; données ; erreur 404 et « Réessayer » ; `marketData` `null` (« Aucun historique… ») ; un seul point (texte à la place de la courbe) ; `stale` ; indicateur `null` (« — » et mention de l'historique) |
| `test/widget_test.dart` | Appui sur une carte du catalogue → fiche de l'ETF ; retour → liste |

Rappel : `flutter test` compile les shaders avec `impellerc`, ce qui peut déclencher une demande d'autorisation macOS.

---

## 15. Découpage en commits

Branche `feat/mobile/etf-detail`, depuis `main`, à merger en même temps que `feat/backend/etf-detail-chart` :

1. `📝 : mobile - plan the etf detail screen` (ce plan)
2. `♻️ : mobile - extract the error view widget` (`ErrorView`, catalogue, test)
3. `🔧 : mobile - add fl_chart for charts` (`pubspec.yaml`, `pubspec.lock`, `CLAUDE.md`)
4. `✨ : mobile - show etf details from the catalog` (sections 5 à 14)

---

## 16. Critères de fin

- [ ] `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze` (aucun avertissement) et `flutter test` passent.
- [ ] Backend lancé sur la branche `feat/backend/etf-detail-chart` : un appui sur SPY ouvre sa fiche, avec la courbe ouverte sur la dernière année, le défilement vers le passé et l'info-bulle au toucher.
- [ ] Retour à la liste par la flèche et par le geste système, barre de navigation visible.
- [ ] Ticker inconnu (`/compare/etf/ARKK`) : « Cet ETF est introuvable. »
- [ ] Backend arrêté : message d'erreur, puis « Réessayer » recharge la fiche.
- [ ] Aucun calcul de donnée métier côté mobile (la variation de l'info-bulle vient de l'API), ni couleur ou `TextStyle` en dur dans les nouveaux widgets.
- [ ] Points à retravailler après essai (fenêtre, échelle verticale, lisibilité) notés pour l'utilisateur.

---

## 17. Ajustements pendant le développement

Écarts entre ce plan et le code livré :

| Sujet | Plan | Code livré | Raison |
|---|---|---|---|
| `IndicatorTile` | `infoTitle` et `infoText` | `infoText` seul : le titre de la bulle reprend le libellé de la ligne | Le titre était toujours identique au libellé (un paramètre de moins) |
| Titres de section | Non prévu | Widget privé `_SectionTitle` (titre et bulle « i » facultative) dans l'écran, pour la courbe, les rendements, le risque et la fourchette | Sert seulement à cet écran : pas extrait dans `lib/widgets/` |
| Info-bulle de la courbe | Une ligne : « 12/03/2024 · 512,40 USD · +13,87 % depuis le 12/10/2021 » | Trois lignes (date, cours, variation) | Plus lisible dans la largeur d'une info-bulle |
| Affichage de l'info-bulle | Au toucher | **Appui long** (environ une demi-seconde) | Avec le défilement activé, un glissement fait défiler la courbe : fl_chart n'affiche l'info-bulle qu'après un appui maintenu. À évaluer lors des essais |
| Fenêtre initiale | À vérifier dans l'API de fl_chart 1.3.0 | Matrice initiale du `TransformationController` : agrandissement de `nombre de points / 252` (au moins 1) et décalage sur la fin. Le contrôleur est créé au premier `build`, quand la largeur de la courbe est connue | fl_chart redessine la courbe sur la fenêtre choisie, sans l'agrandir visuellement |
| Fermeture de la boîte de dialogue | Non précisé | `Navigator.of(context).pop()` | Une boîte de dialogue n'est pas une route go_router : c'est la façon standard de la fermer |
| Fourchette et titres | Non prévu | Libellés en `Flexible` / `Expanded` | Évite un débordement sur un écran étroit, détecté par les tests |
| Rendements | Quatre lignes `IndicatorTile`, une bulle chacune | Tableau horizontal `ReturnsTable` (1 an, 3 ans, 5 ans) avec une seule bulle sur le titre « Rendements », puis la ligne « Annualisé sur 5 ans » avec sa bulle | Demande après les premiers essais : un tableau se lit plus vite pour comparer les périodes |
| Couleurs des rendements | Non prévu | Vert si positif, rouge si négatif, neutre si nul ou absent, pour les rendements seulement (ni la perte maximale, ni la volatilité). Sens donné par `ValueTrend` (`lib/utils/number_formatting.dart`), couleurs dans l'extension de thème `GainLossColors` (`lib/theme/`) : vert `0xFF2E7D32`, rouge `colorScheme.error`. Le signe « + » / « - » reste affiché pour qui distingue mal les couleurs | Lecture immédiate du sens de la variation, sans calcul : seul le signe de la valeur reçue est lu |


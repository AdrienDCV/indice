# Plan d'implémentation : animations

> Les conventions du projet sont définies dans le `CLAUDE.md` mobile, qui fait foi. Ce plan ne décrit que la fonctionnalité.

## Avant de coder

1. **Lis le code existant** : `lib/pages/main_page.dart` et `lib/widgets/module_button.dart` (animations explicites déjà en place), `lib/widgets/indicator/correlation_gauge.dart`, `lib/widgets/card/etf_card.dart`, `lib/screens/compare/etf_comparison_screen.dart`, `lib/screens/compare/etf_detail_screen.dart`, `lib/stores/etf/etf_catalog_store.dart`, `lib/stores/etf/etf_detail_store.dart` et les tests correspondants.
2. **Présente ton plan** (fichiers créés, modifiés et supprimés) et attends la validation avant d'écrire du code.

---

## 1. Objectif

Le sujet demande **au moins trois animations, dont au moins deux développées par nous-mêmes**. L'application en compte déjà deux, faites maison et explicites (`AnimationController`) :
- la transition entre onglets (`MainPage`) : fondu et légère remontée, 250 ms ;
- l'enfoncement du bouton de module (`ModuleButton`) : réduction à 95 %, 120 ms.

Le `Hero` entre le champ « Choisir un ETF » et la barre de recherche du sélecteur reste en place, mais il n'est pas compté : c'est une transition de page fournie par Flutter, et elle est quasi invisible.

Ce plan ajoute trois animations visibles, au service de la lecture des données :
- **A** : le curseur de la jauge de corrélation glisse du centre vers sa valeur ;
- **C** : les cartes de résultat apparaissent quand elles arrivent à l'écran, en cascade (comparaison et fiche ETF) ;
- **D** : l'étoile des favoris rebondit quand elle change.

Ces animations ne font que de l'affichage : elles animent des valeurs déjà reçues de l'API, sans rien recalculer.

## 2. Hors périmètre

- La barre plus bas / plus haut de la fiche ETF (`PriceRangeBar`) : pas d'animation.
- Le graphique d'évolution (courbe qui se dessinerait) : écarté au cadrage.
- L'onglet Apprendre (`lib/pages/`) : code en attente du refactoring de migration.
- Toute modification des stores et du contrat d'API.
- Le retrait du `Hero` du sélecteur d'ETF.

## 3. Décisions issues du cadrage

| Sujet | Décision |
|---|---|
| A, point de départ | Le curseur part **toujours du centre** (0) et glisse vers la gauche ou la droite jusqu'à la valeur de corrélation |
| A, déclenchement | **Quand la carte « Corrélation » apparaît à l'écran** (section 5), et non au chargement : la carte est en bas de la comparaison, une animation jouée au chargement se déroulerait hors de l'écran |
| A, rejeu | À chaque nouvelle paire comparée, il repart du centre |
| A, technique | `TweenAnimationBuilder` (animation implicite paramétrée), de 0 à la valeur |
| C, écrans | Écran de comparaison **et** fiche ETF |
| C, déclenchement | **Au défilement** : une carte apparaît la première fois qu'elle entre à l'écran. Celles qui sont visibles au chargement apparaissent en cascade. Une carte déjà apparue ne rejoue pas son animation si l'on remonte |
| C, effet | Chaque bloc apparaît en fondu en remontant de 16 px, en 400 ms ; quand plusieurs blocs entrent à l'écran en même temps, chacun démarre 80 ms après le précédent |
| C, rejeu | À chaque nouvelle paire comparée et à l'ouverture d'une fiche. Pas au rafraîchissement (tirer vers le bas) de la fiche |
| C, technique | Animation explicite, faite maison sans dépendance : un `AnimationController` par bloc, dans un widget réutilisable `RevealOnScrollColumn` qui écoute le défilement. Le paquet `visibility_detector` a été écarté (dépendance en plus, dernière version publiée il y a 3 ans) |
| D, effet | L'étoile s'agrandit à 130 % puis revient à sa taille, en 300 ms, **à chaque changement** (ajout comme retrait) |
| D, moment | Quand l'état du store change, sans modifier les stores (voir l'encadré ci-dessous) |
| D, technique | Animation explicite : un `AnimationController`, déclenché quand `isFavourite` change, dans un widget `FavouriteIcon` |
| Accessibilité | Si le téléphone demande de réduire les animations (`MediaQuery.disableAnimationsOf(context)`), A, C et D s'affichent directement dans leur état final |
| Durées | Ajustables après un essai sur téléphone ; tout changement est consigné dans la section 10 |

> **Correction après le cadrage (D, moment)** : au cadrage, j'avais indiqué que l'étoile change seulement après la réponse du backend (option a). C'est faux : `EtfCatalogStore.toggleFavourite` et `EtfDetailStore.toggleFavourite` changent **déjà** l'étoile tout de suite, puis la remettent dans son état d'origine si le backend répond par une erreur (affichage « optimiste »). Pour respecter la décision « on ne touche pas aux stores », le rebond suit ce comportement existant : il se joue dès le toucher et, en cas d'erreur, une deuxième fois quand l'étoile revient en arrière (le message d'erreur actuel s'affiche en même temps). **À valider.**

## 4. A — Jauge de corrélation (`lib/widgets/indicator/correlation_gauge.dart`)

- Le curseur (`Align` dans le `Stack`) est construit par un `TweenAnimationBuilder<double>`, 600 ms, courbe `Curves.easeOutCubic`. L'alignement horizontal du curseur est la valeur animée.
- Le `Tween` va de 0 à `value.clamp(-1, 1)` si la carte est apparue (`RevealOnScrollColumn.isRevealed(context)`), et de 0 à 0 sinon : tant que la carte n'est pas à l'écran, le curseur reste au centre. Quand elle apparaît, la fin du `Tween` change et le curseur glisse vers sa valeur.
- En dehors d'une `RevealOnScrollColumn`, `isRevealed` vaut `true` : le curseur glisse dès l'affichage.
- Avec « réduire les animations », la durée est `Duration.zero` : le curseur est posé directement.
- **Rejeu** : pendant le chargement d'une nouvelle paire, l'écran de comparaison affiche la roue de chargement à la place du résultat (`EtfComparisonStore` passe `isLoading` à `true`). La jauge est donc reconstruite à chaque nouvelle paire et repart de 0.
- L'API du widget ne change pas (`CorrelationGauge(value: ...)`).

## 5. C — Apparition au défilement (`lib/widgets/animation/reveal_on_scroll_column.dart`)

### Widget

`RevealOnScrollColumn` remplace une `Column` et reprend ses paramètres utiles : `children`, `spacing`, `crossAxisAlignment`.

- `StatefulWidget` avec `TickerProviderStateMixin` (plusieurs contrôleurs) : un `AnimationController` de 400 ms par enfant, et une `GlobalKey` par enfant pour retrouver sa position.
- Il écoute la position de défilement de la page (`Scrollable.maybeOf(context)`). Après chaque image où la page a défilé, et après la première image, il cherche les enfants pas encore apparus qui sont au moins en partie dans la zone visible de la page. La vérification se fait **après** le calcul des positions (`addPostFrameCallback`) : faite pendant le défilement, elle lirait les positions de l'image précédente.
- Les enfants trouvés lors d'une même vérification démarrent l'un après l'autre, à 80 ms d'écart (`Timer`), dans l'ordre de la colonne. Un enfant ne démarre qu'une fois.
- Chaque enfant est enveloppé dans une `Opacity` (de 0 à 1) et un `Transform.translate` (de 16 px vers 0), selon la courbe `easeOutCubic`. `SlideTransition` est écarté, car son décalage est proportionnel à la hauteur de l'enfant, et les cartes ont des hauteurs très différentes.
- **Signal aux enfants** : `RevealOnScrollColumn.isRevealed(context)` indique à un widget descendant si son bloc a commencé à apparaître (un `InheritedWidget` privé, qui ne prévient ses dépendants que quand la valeur change). La jauge s'en sert (section 4).
- Hors d'une page qui défile, tous les enfants apparaissent dès la première image.
- Avec « réduire les animations », les contrôleurs sont créés à la fin (`value = 1`) : tout est affiché tout de suite.
- **Limite connue** : un enfant ajouté après la première construction (par exemple une bannière qui apparaît après un rafraîchissement) est affiché directement, sans animation. Les contrôleurs sont associés aux enfants par leur position dans la liste : si un bloc s'insère en tête alors que des cartes du bas ne sont pas encore apparues, ce sont les animations des blocs suivants qui se décalent. Ce cas est rare (rafraîchissement de la fiche qui fait apparaître ou disparaître la bannière de données périmées) et n'a pas d'autre effet que visuel.

### Écrans

| Écran | `Column` remplacée | Blocs |
|---|---|---|
| Comparaison (`_ComparisonView`) | La `Column` racine (`spacing: 12`, `stretch`) | Période commune, bannières de données périmées, « Évolution », « Indicateurs », « Corrélation », note sur les performances passées |
| Fiche ETF (`_MarketDataView`) | La `Column` des données de marché (`spacing: 12`, `stretch`) | Bannière périmée, « Évolution du cours », « Rendements », « Risque », « Fourchette sur 52 semaines » |

L'en-tête de la fiche (nom, ticker, cours, bouton « Comparer cet ETF ») reste fixe : il s'affiche tout de suite, et seules les cartes de données apparaissent.

**Rejeu** : il est automatique, sans clé ni code en plus. Sur la comparaison, une nouvelle paire passe par la roue de chargement, qui retire puis recrée la colonne. Sur la fiche, chaque ouverture crée un nouvel écran, et `refresh()` ne passe pas par le chargement (`showLoading: false`) : la colonne reste en place, sans nouvelle animation.

## 6. D — Rebond de l'étoile (`lib/widgets/favourite/favourite_icon.dart`)

### Widget

`FavouriteIcon({required bool isFavourite, Color? color})` affiche `Icons.star` ou `Icons.star_border`.

- `StatefulWidget` avec `SingleTickerProviderStateMixin`, contrôleur de 300 ms.
- Échelle : `TweenSequence` de 1 à 1,3 (première moitié, `easeOut`), puis de 1,3 à 1 (seconde moitié, `easeIn`), appliquée avec un `ScaleTransition`.
- `didUpdateWidget` : si `isFavourite` a changé, `forward(from: 0)`, sauf avec « réduire les animations ».
- Pas d'animation à la première construction : une étoile déjà pleine à l'ouverture ne rebondit pas.

### Utilisations

- `EtfCard` : `IconButton(icon: FavouriteIcon(isFavourite: isFavourite, color: theme.colorScheme.primary))`.
- Fiche ETF, `_FavouriteButton` : `IconButton(icon: FavouriteIcon(isFavourite: etf.favourite))`. La couleur vient du thème de l'`AppBar`, comme aujourd'hui.

## 7. Tests

| Fichier | Cas |
|---|---|
| `test/widgets/indicator/correlation_gauge_test.dart` (adapté) | Le curseur est au centre au premier affichage ; il est entre le centre et la valeur à mi-parcours, puis à la valeur ; dans une `RevealOnScrollColumn`, il reste au centre tant que sa carte est hors de l'écran, puis glisse quand on fait défiler jusqu'à elle ; avec `disableAnimations`, il est à la valeur dès le premier affichage |
| `test/widgets/animation/reveal_on_scroll_column_test.dart` (nouveau) | Les enfants sont transparents au départ ; les enfants visibles apparaissent ; le premier démarre avant le second ; un enfant hors de l'écran attend qu'on fasse défiler jusqu'à lui ; `isRevealed` passe de `false` à `true` ; hors d'une page qui défile, tout apparaît ; avec `disableAnimations`, tout est visible dès le premier affichage ; `spacing` et `crossAxisAlignment` sont transmis |
| `test/widgets/favourite/favourite_icon_test.dart` (nouveau) | Bonne icône selon `isFavourite` ; pas de rebond au premier affichage ; l'échelle dépasse 1 pendant l'animation quand `isFavourite` change, puis revient à 1 ; pas de rebond avec `disableAnimations` |
| `test/widgets/card/etf_card_test.dart` | Doit rester vert (les recherches `find.byIcon(Icons.star)` trouvent toujours l'icône) |
| Tests des écrans (`etf_comparison_screen_test.dart`, `etf_detail_screen_test.dart`, `etf_catalog_screen_test.dart`, `etf_picker_screen_test.dart`) | Ajouter `pumpAndSettle` là où un test lit une position ou tape sur un élément encore en cours d'animation |

`MediaQuery(data: MediaQueryData(disableAnimations: true), ...)` sert à simuler l'option d'accessibilité dans les tests.

## 8. Découpage en commits

1. `💄 : mobile - reveal result cards and the correlation gauge on scroll` (avec ce plan) : A et C, réunies parce que la jauge dépend de l'apparition de sa carte
2. `💄 : mobile - bounce the favourite star on change`

Chaque commit passe `flutter analyze` et `flutter test`.

## 9. Critères de fin

- Les trois animations sont visibles sur téléphone : la jauge quand on descend jusqu'à la corrélation, l'apparition des cartes sur la comparaison et sur la fiche, l'étoile dans le catalogue et sur la fiche.
- Avec « réduire les animations » activé sur le téléphone, rien ne bouge et tout s'affiche correctement.
- `flutter analyze` ne signale rien, et `flutter test` passe.
- Aucun store, repository ni model modifié.

## 10. Ajustements pendant le développement

- **Apparition au défilement (A et C)** : la première version jouait la jauge et la cascade au chargement. La carte « Corrélation » étant en bas de l'écran, l'animation se déroulait sans être vue. Le déclenchement se fait désormais quand chaque carte entre à l'écran (`StaggeredColumn` remplacé par `RevealOnScrollColumn`), et A et C sont livrées dans le même commit.

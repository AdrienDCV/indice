# ADR-0003 — Signaler les ETF à effet de levier ou inverses d'après leur nom

- **Statut** : Acceptée
- **Date** : 2026-11-02

## Contexte

Le catalogue complet ([ADR-0001](0001-catalogue-complet-des-etf-americains.md)) contient des ETF à effet de levier (qui amplifient chaque jour les variations d'un indice) et des ETF inverses (qui en prennent le sens opposé). Conçus pour des opérations de très court terme, ils sont risqués pour un débutant, et un simple rappel général sur l'écran du catalogue ne permet pas de les reconnaître.

Twelve Data ne fournit aucune information sur la stratégie d'un ETF : seul son nom la révèle. L'ADR-0001 a écarté l'**exclusion** de ces ETF pour cette raison : un repérage par le nom n'est pas assez fiable pour retirer des ETF du catalogue.

Mesure sur le catalogue local (11 422 ETF, novembre 2026) :
- une règle naïve (« ultra », « short », « daily ») repère 1 018 ETF, avec de nombreuses erreurs : « Ultra-Short Bond », « Short-Term Muni », « Daily Income », « Long/Short » ;
- une règle stricte (ci-dessous) en repère 782, et les 30 tirés au hasard pour vérification étaient tous à effet de levier ou inverses.

## Décision

Le backend **signale** ces ETF, sans les exclure : `Etf.isLeveragedOrInverse()` applique au nom une règle stricte, exposée par le champ `leveragedOrInverse` dans le catalogue et dans la fiche. Un nom est retenu s'il contient :
- un multiplicateur (`2x`, `3X`, `-1x`, `1.25x`…) ;
- les mots `Inverse`, `Leverage` ou `Leveraged` ;
- ou commence par `ProShares Ultra`, `ProShares UltraPro` ou `ProShares UltraShort`.

L'application mobile affiche une étiquette « Effet de levier ou inverse », avec une explication qui précise que le repérage se fait d'après le nom.

## Alternatives envisagées

- **Rappel général seul** : aucun risque d'erreur, mais l'utilisateur ne sait pas quels ETF sont concernés. Écarté : insuffisant pour un public débutant.
- **Règle naïve sur les mots-clés** : repère davantage d'ETF, mais en signale à tort beaucoup d'ordinaires (fonds obligataires « Ultra-Short »). Écartée.
- **Liste de tickers tenue à la main** : précise, mais impossible à maintenir sur plus de 11 000 ETF. Écartée.
- **Autre source de données** : aucune source gratuite testée ne fournit la stratégie des ETF. Écartée.

## Conséquences

### Positives
- Les ETF à effet de levier ou inverses courants sont signalés, sans nouvelle source ni appel supplémentaire.
- La règle est dans l'objet métier : testable unitairement, et le mobile n'applique aucune logique.

### Négatives / compromis assumés
- Un ETF dont le nom ne le dit pas n'est pas signalé (ex. « ProShares Short S&P500 », inverse) : le rappel général reste affiché sous la recherche.
- Un ETF ordinaire dont le nom contient un multiplicateur ou ces mots serait signalé à tort.

### Points de vigilance
- Si des erreurs de repérage sont signalées, compléter la règle et ses tests plutôt que d'ajouter des exceptions au cas par cas.
- Si une source fiable de la stratégie des ETF devient disponible, remplacer cette règle.

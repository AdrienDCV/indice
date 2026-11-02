# ADR-0001 — Catalogue complet des ETF américains

- **Statut** : Acceptée
- **Date** : 2026-11-01

## Contexte

Le catalogue proposait jusqu'ici 10 ETF choisis à la main pour leur intérêt pédagogique (`etf.catalog.selected-tickers` dans `application.yaml`), parmi les ETF américains que renvoie l'annuaire de Twelve Data (`GET /etfs?country=United States`, un seul appel). L'offre gratuite de Twelve Data ne fournit, pour chaque ETF, que des informations d'identité (ticker, nom, place de cotation, devise) : aucune catégorie, zone géographique ni frais ne permet de proposer des filtres riches sur une petite liste.

Avec 10 ETF, le catalogue tenait en une page et une recherche n'avait pas d'intérêt.

## Décision

Le catalogue contient **tous les ETF** renvoyés par l'annuaire de Twelve Data pour le pays configuré (`etf.catalog.country`). La liste `selected-tickers` est supprimée ; le dédoublonnage par ticker est conservé.

Pour rendre ce catalogue utilisable, `GET /etfs` accepte une **recherche** (`search` : début du ticker ou partie du nom, sans tenir compte des majuscules) et un **filtre favoris** (`favourites=true`, voir [ADR-0002](0002-favoris-cote-backend-utilisateur-unique.md)), appliqués en base avec la pagination.

## Alternatives envisagées

- **Garder une liste choisie, agrandie si besoin** : simple (une ligne par ETF dans `application.yaml`), lisible pour un débutant, et le catalogue tient en une page. Écartée : l'équipe préfère proposer tout l'éventail des ETF disponibles et le parcourir par la recherche.
- **Exclure les ETF à effet de levier ou inverses** : seuls leurs noms les trahissent (« 2X », « Ultra », « Bear »…), ce qui n'est pas fiable. Écartée : l'application mobile affiche plutôt un rappel général sur ces produits.

## Conséquences

### Positives
- Tous les ETF américains de l'offre gratuite sont consultables et comparables.
- La synchronisation reste un seul appel à Twelve Data par semaine.

### Négatives / compromis assumés
- Côté mobile : pagination au défilement, recherche, et sélecteurs de la comparaison avec recherche deviennent nécessaires.
- Le catalogue contient des produits complexes (effet de levier, inverses) mêlés aux ETF classiques.
- La première synchronisation enregistre plusieurs milliers d'ETF.

### Points de vigilance
- Durée de la synchronisation : si elle devient gênante, envisager une insertion par lots.
- Formats : `etf.exchange` (`VARCHAR(10)`) et le format de ticker accepté par la fiche (`^[A-Z0-9.-]{1,10}$`) doivent couvrir toutes les valeurs renvoyées par Twelve Data.
- Quota : chaque fiche ouverte pour la première fois de la journée coûte un appel (8 par minute au plus) ; un usage intensif pourrait l'atteindre.

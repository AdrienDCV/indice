# ADR-0002 — Favoris stockés côté backend, application à utilisateur unique

- **Statut** : Acceptée
- **Date** : 2026-11-01

## Contexte

L'utilisateur doit pouvoir épingler des ETF en favori et n'afficher que ceux-là dans le catalogue. Le catalogue complet ([ADR-0001](0001-catalogue-complet-des-etf-americains.md)) compte plusieurs milliers d'ETF, paginés en base : le filtre doit donc être appliqué par le backend.

L'application n'a **pas d'authentification**, et le sujet du projet n'en impose pas. Elle est considérée comme ayant **un seul utilisateur**.

## Décision

Les favoris sont stockés **côté backend**, dans une table `favourite_etf` qui ne contient que le ticker (clé primaire, et clé étrangère vers `etf (ticker)` en `ON DELETE CASCADE`). Ils ne sont rattachés à aucun utilisateur.

- `PUT /etfs/{ticker}/favourite` épingle un ETF : 201 s'il ne l'était pas, 200 s'il l'était déjà (PUT est idempotent).
- `DELETE /etfs/{ticker}/favourite` le retire : 204 dans tous les cas.
- `GET /etfs?favourites=true` filtre le catalogue, et chaque ETF renvoyé porte un champ `favourite`.

## Alternatives envisagées

- **Favoris sur le téléphone** (Shared Preferences), envoyés au backend pour filtrer (`GET /etfs?tickers=SPY,BND`) : favoris propres à chaque appareil et modifiables hors ligne. Écartée : l'équipe préfère que le système soit déjà en place côté serveur le jour où une authentification sera ajoutée.
- **Favoris par appareil** (identifiant anonyme envoyé dans un en-tête, table `favourite_etf (device_id, ticker)`) : favoris séparés sans authentification. Écartée : complexité supplémentaire (identifiant, en-tête) sans besoin, l'application ayant un seul utilisateur.

## Conséquences

### Positives
- Le filtre favoris est appliqué en base, avec la pagination et la recherche.
- Le jour d'une authentification, il suffira d'ajouter une colonne utilisateur à `favourite_etf`.
- Un ETF retiré du catalogue perd automatiquement son favori.

### Négatives / compromis assumés
- Tous les appareils connectés au même backend partagent les mêmes favoris.
- Épingler ou retirer un favori demande le réseau.

### Points de vigilance
- Ajout d'une authentification ou d'un second utilisateur : rattacher les favoris à un utilisateur (nouvelle colonne, migration des favoris existants) et remplacer cette ADR.

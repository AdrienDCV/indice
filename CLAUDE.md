# CLAUDE.md — Indice

## Projet

**Indice** est une application mobile pédagogique qui aide les débutants (étudiants, jeunes actifs) à comprendre l'investissement financier, en particulier les **ETF**. Elle propose trois modules : **Apprendre** (ressources pédagogiques), **Comparer** (fiches et comparaison d'ETF) et, plus tard, **Construire** (portefeuille fictif).

Contraintes non négociables, pour les deux projets :
- aucune transaction réelle, aucune connexion bancaire ou courtier ;
- **aucun conseil en investissement** : l'application compare et explique, avec des libellés factuels et neutres.

## Organisation du dépôt

```
indice/
├── indice-backend/   # API REST : Kotlin, Spring Boot 4, PostgreSQL, Flyway
└── indice_mobile/    # Application Flutter
```

- **Le backend porte toute la logique métier.** L'application Flutter reste « bête » : elle affiche les données reçues de l'API et ne recalcule rien.
- Chaque projet a ses propres conventions, qui font foi dans son périmètre :
  - `indice-backend/CLAUDE.md` : architecture, règles de code, tests, migrations ;
  - `indice-backend/docs/` : glossaire (`glossaire.md`) et plans d'implémentation (`plans/`) ;
  - `indice_mobile/CLAUDE.md` : à rédiger.
- Ce fichier ne contient que les règles **communes** aux deux projets : Git, commits et pull requests.

## Façon de travailler

- Une tâche concerne **un seul projet** à la fois, sauf demande explicite. Si une modification du backend change le contrat d'API (format de réponse, clés d'erreur…), le signaler, car l'application Flutter devra suivre.
- **Ne jamais commiter ni pusher sans demande explicite.**
- Ne jamais commiter de brouillons, de fichiers générés pour l'utilisateur (description de PR…) ni de secrets. Vérifier les fichiers non suivis (`git status`) avant de proposer un `git add`, et préférer un ajout ciblé à `git add .`.

## Commits

### Format

```
<gitmoji> : <scope> - <message>
```

- **`<gitmoji>`** : un seul emoji, qui décrit la nature du changement (voir le tableau ci-dessous).
- **`<scope>`** : le projet concerné, `backend` ou `mobile`. Il est omis seulement pour un changement qui concerne tout le dépôt (ex. `🎉 : init backend and mobile projects`).
- **`<message>`** : en **anglais**, en **minuscules**, à l'impératif, court (moins de 72 caractères au total) et sans point final.
- Un seul espace de chaque côté du `:` et du `-`.
- **Un commit ne mélange pas les deux projets** : faire un commit par scope.

### Gitmojis utilisés

| Gitmoji | Usage |
|---|---|
| 🎉 | Initialisation d'un projet |
| ✨ | Nouvelle fonctionnalité |
| 🐛 | Correction de bug |
| ♻️ | Refactoring sans changement de comportement |
| 🔧 | Configuration (fichiers de config, dépendances, `CLAUDE.md`…) |
| ✅ | Ajout ou modification de tests uniquement |
| 📝 | Documentation (`docs/`, README…) |
| 🗃️ | Migration ou changement de schéma de base de données |
| 💄 | Interface utilisateur et style (mobile) |
| 🔥 | Suppression de code ou de fichiers |
| 🚑️ | Correctif urgent |

### Exemples

```
✨ : backend - add paginated etf catalog endpoint synced with eodhd
🐛 : backend - fix media type detection
🔧 : mobile - config mobile project
💄 : mobile - add etf card component
```

Quand l'utilisateur demande un titre de commit, proposer **un seul** titre conforme. Si les changements relèvent des deux projets, proposer un commit par projet.

## Pull requests

### Titre

Même format que les commits : `<gitmoji> : <scope> - <message>`.

### Description

Rédigée en **français**, en Markdown, avec exactement ces trois sections :

```markdown
## Contexte

En quelques phrases : le besoin couvert et le contenu de la PR.

## Travail réalisé

Le travail réalisé, regroupé par thème (endpoint, logique métier, architecture,
infrastructure, tests, documentation…). Mentionner les dépendances ajoutées,
les migrations et tout changement de contrat d'API.

## Points d'attention

Ce sur quoi le reviewer doit porter une attention particulière :
choix discutables, limites connues, risques, prérequis pour tester,
impacts sur l'autre projet, fichiers commités par erreur…
```

Règles de rédaction :
- **S'appuyer sur le contenu réel de la branche** (`git log`, `git diff --stat` par rapport à `main`), et non sur le souvenir de la conversation. Signaler tout fichier présent dans la PR qui ne devrait pas y être.
- Être factuel : ne pas présenter comme vérifié ce qui ne l'a pas été (ex. un appel à une API externe testé seulement avec un faux token).
- Indiquer comment tester (prérequis, commandes, profil Spring…) dès que ce n'est pas évident.
- Les points d'attention sont concrets et actionnables, pas une liste de précautions génériques.

### Livraison

Le texte se copie mal depuis le terminal. Quand l'utilisateur demande une description de PR :
1. l'écrire dans un fichier `pr-description.md` à la racine du projet concerné (fichier temporaire, **jamais commité**) ;
2. la copier dans le presse-papiers avec `pbcopy < pr-description.md` ;
3. rappeler de supprimer le fichier une fois la PR créée.

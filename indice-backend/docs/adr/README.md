# Architectural Decision Records — backend

Une ADR capture **une** décision d'architecture ou de conception structurante : le contexte qui l'a motivée, la décision prise, les alternatives écartées et les conséquences assumées.

Elles servent de mémoire du projet : on doit pouvoir comprendre *pourquoi* le code est ainsi sans avoir assisté à la discussion.

## Quand écrire une ADR ?

- Introduction d'un pattern ou d'une convention qui s'appliquera partout
- Choix ou abandon d'une technologie, d'une librairie structurante
- Écart volontaire à une règle du [CLAUDE.md](../../CLAUDE.md)
- Décision difficile à défaire, ou qui a fait l'objet d'un vrai débat

Pas besoin d'ADR pour un détail d'implémentation local et réversible.

## Cycle de vie

| Statut | Signification |
|---|---|
| `Proposée` | En discussion, pas encore appliquée |
| `Acceptée` | Décision en vigueur |
| `Dépréciée` | Plus pertinente, sans remplaçante |
| `Remplacée par ADR-XXXX` | Une décision plus récente la supplante |

Une ADR acceptée **ne se réécrit pas** (hors coquilles) : on crée une nouvelle ADR qui la remplace.

Nouvelle ADR : copier [0000-template.md](0000-template.md), numéroter à la suite, ajouter la ligne dans l'index.

## Organisation

- **Ici** (`indice-backend/docs/adr/`) : les décisions propres au backend.
- Les décisions propres à l'application mobile sont dans `indice_mobile/docs/adr/`, et les décisions **transverses** au dépôt iront dans `docs/adr/` à la racine.

Chaque dossier a sa propre numérotation. Pour citer une ADR hors de son dossier, on donne son lien.

## Index

| N° | Titre | Statut |
|---|---|---|
| [0001](0001-catalogue-complet-des-etf-americains.md) | Catalogue complet des ETF américains | Acceptée |
| [0002](0002-favoris-cote-backend-utilisateur-unique.md) | Favoris stockés côté backend, application à utilisateur unique | Acceptée |

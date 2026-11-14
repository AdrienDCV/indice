# ADR-0002 — Ressources favorites consultables hors ligne

- **Statut** : Acceptée
- **Date** : 2026-11-14

## Contexte

L'[ADR 0001](0001-favoris-consultables-hors-ligne.md) rend les fiches des ETF favoris consultables hors ligne. Rien n'était gardé côté ressources pédagogiques : sans réseau, l'onglet Apprendre et la fiche d'une ressource affichaient une erreur, alors que le sujet demande que l'application conserve un intérêt sans connexion.

Il y a aujourd'hui 6 ressources : 3 articles, dont le contenu est du texte renvoyé par l'API, et 3 vidéos YouTube. Une vidéo YouTube ne peut pas être téléchargée (conditions d'utilisation de YouTube), et le lecteur intégré demande le réseau.

## Décision

**Les ressources suivent la règle des ETF : épingler une ressource, c'est la télécharger.** Nous donnons la priorité à ce que l'utilisateur veut pouvoir consulter rapidement : ses favoris.

- **À l'épinglage**, après `PUT /resources/{id}/favourite`, l'application demande la fiche (`GET /resources/{id}`) et l'enregistre dans `api_cache/resource_detail_<id>.json`, avec la date d'enregistrement. Si ce téléchargement échoue, le favori reste enregistré : la fiche sera téléchargée au prochain démarrage en ligne.
- **À chaque ouverture en ligne** d'une fiche favorite, le fichier est mis à jour ; au **retrait du favori**, il est supprimé.
- **Au démarrage**, en ligne, l'application télécharge les fiches des favoris qui manquent et supprime celles des ressources qui ne sont plus favorites.
- **Hors ligne**, l'onglet Apprendre affiche les favoris téléchargés, et chaque fiche s'ouvre avec la date et l'heure de dernière récupération. Le texte d'une vidéo reste lisible, mais la vidéo elle-même ne l'est pas.

## Alternatives envisagées

- **Garder toutes les ressources** : possible avec 6 ressources, mais c'est une seconde règle à côté de celle des ETF, et le principe « garder les réponses de l'API » a déjà été écarté par l'ADR 0001. Il ne tiendrait plus avec un catalogue de ressources plus grand.
- **Faire renvoyer la fiche par `PUT /resources/{id}/favourite`**, comme pour les ETF : écartée. Pour un ETF, ce choix évite un appel à Twelve Data, limité à 8 par minute ; une fiche de ressource ne coûte aucun appel externe, et un `GET` après l'épinglage évite de changer le contrat d'API.

## Conséquences

### Positives
- Une seule règle pour l'utilisateur, ETF comme ressources : ce qu'il a épinglé reste consultable sans réseau.
- Aucun changement du backend ni du contrat d'API ; le stockage, le bandeau et la reconnexion des ETF sont réutilisés.

### Négatives / compromis assumés
- Les ressources non favorites, la recherche et les filtres de niveau ne sont pas disponibles hors ligne.
- Les vidéos ne se lisent pas hors ligne : la fiche affiche sa vignette et indique que la vidéo demande une connexion.
- Épingler une ressource envoie deux requêtes au lieu d'une.

### Points de vigilance
- Si une ressource devait contenir des fichiers lourds (images, PDF), leur téléchargement serait à prévoir à part : seul le JSON de l'API est gardé.

# ADR-0001 — Favoris consultables hors ligne, enregistrés en fichiers locaux

- **Statut** : Acceptée
- **Date** : 2026-11-02

## Contexte

Le sujet du projet (§6, « Fonctionnement hors connexion ») demande que l'application conserve un intérêt sans réseau : *« favoris, portefeuille, simulations, historiques déjà téléchargés ou dernières valeurs connues pourront rester consultables »*. L'utilisateur doit pouvoir *« identifier qu'il consulte éventuellement une donnée ancienne, par exemple en affichant la date et l'heure de dernière actualisation »*, et le fonctionnement pourra être testé en soutenance *« après fermeture complète de l'application et désactivation du réseau »*. Trois techniques de stockage local ont été présentées en cours : SQLite, les fichiers locaux et Shared Preferences.

Le catalogue compte plus de 11 000 ETF, paginés et filtrés par le backend (recherche, favoris). Une première version gardait les réponses de l'API (première page du catalogue, fiches consultées) : avec le catalogue complet, elle ne gardait que 50 ETF sur plus de 11 000, rendait inaccessibles hors ligne les fiches consultées (la recherche demande le réseau) et accumulait des fichiers sans limite.

## Décision

**Seuls les favoris sont consultables hors ligne**, sur le modèle des téléchargements des services de musique : chez Deezer, *« You can't download tracks unless you add them to your library or to a playlist »* ; chez Spotify, on télécharge *« albums, playlists, and podcasts »* pour les écouter sans connexion. Ici, **épingler un ETF, c'est le télécharger** :

- **À l'épinglage**, `PUT /etfs/{ticker}/favourite` renvoie la fiche de l'ETF, enregistrée aussitôt dans un fichier JSON du dossier cache de l'application (`path_provider`) : `api_cache/etf_detail_<TICKER>.json`, avec la date d'enregistrement et la réponse brute de l'API.
- **À chaque ouverture en ligne** d'une fiche favorite, le fichier est mis à jour ; une fiche qui n'est pas favorite n'est jamais gardée.
- **Au retrait du favori**, le fichier est supprimé, comme on supprime un téléchargement.
- **Au démarrage**, en ligne, l'application télécharge les fiches des favoris qui manquent (application réinstallée, dossier vidé par le système) et supprime celles des ETF qui ne sont plus favoris, sans rafraîchir les fiches présentes.
- **Hors ligne**, le catalogue affiche les favoris téléchargés, et chaque fiche s'ouvre avec la date et l'heure de dernière récupération. La lecture des fichiers n'a lieu qu'en cas d'erreur réseau ou 5xx, jamais pour une erreur 4xx.

## Alternatives envisagées

- **Cache des réponses de l'API** (première version : première page du catalogue et fiches consultées) : écarté, pour les raisons données dans le contexte. Il convenait à un catalogue de 10 ETF, pas à un catalogue paginé de plus de 11 000.
- **SQLite** : la documentation Flutter la recommande pour une application qui doit *« persist and query large amounts of data on the local device »*. Écartée : on garde un petit ensemble choisi par l'utilisateur, consulté sans recherche. Une recherche hors ligne reproduirait en outre côté mobile une règle du backend.
- **Shared Preferences** : la documentation Flutter la réserve à *« a relatively small collection of key-values »*, précise que *« It's not designed to store large amounts of data »* et que *« There is no guarantee that data will be persisted across app restarts »*. Écartée : une fiche pèse environ 75 Ko et doit être lue après un redémarrage.
- **Limiter le nombre de fiches gardées** : Spotify plafonne les téléchargements (*« as many as 10,000 tracks on each of up to 5 different devices »*) parce que chaque titre pèse plusieurs mégaoctets. Écartée ici : le volume est choisi par l'utilisateur et reste faible (environ 75 Ko par favori, soit environ 7,5 Mo pour 100 favoris), et il le libère en retirant un favori.
- **Rafraîchir toutes les fiches au démarrage** : chaque fiche aux cours de plus d'un jour coûte un appel à Twelve Data, limité à 8 par minute. Écarté : une fiche est mise à jour quand on la rouvre en ligne, et sa date reste affichée.
- **Redis** : écarté d'emblée. C'est un serveur joint par le réseau, pas un stockage embarqué dans l'application.

## Conséquences

### Positives
- Les favoris et leurs fiches restent consultables sans réseau, même après un redémarrage de l'application.
- Le comportement est familier : il reprend celui des téléchargements de Spotify ou Deezer.
- Le JSON de l'API est stocké tel quel et relu avec les `fromJson` existants : aucune conversion côté mobile.

### Négatives / compromis assumés
- Le reste du catalogue, la recherche et la comparaison ne sont pas disponibles hors ligne.
- Épingler un ETF peut coûter un appel à Twelve Data (si ses cours ont plus d'un jour) et prend un peu plus de temps.
- Une fiche téléchargée n'est mise à jour que lorsqu'on la rouvre en ligne : hors ligne, elle peut dater de plusieurs jours, d'où sa date affichée.
- Le système peut vider le dossier cache à tout moment : les fiches sont alors téléchargées de nouveau au démarrage suivant en ligne.
- Nouvelle dépendance : `path_provider` (éditeur flutter.dev).

### Points de vigilance
- Si les utilisateurs gardent un très grand nombre de favoris, la synchronisation au démarrage peut buter sur la limite de Twelve Data : la répartir dans le temps.
- Si l'application devait interroger hors ligne un grand volume de données (recherche dans tout le catalogue, filtres combinés), SQLite redeviendrait pertinente.
- Si le contrat d'API change, un fichier enregistré avant la mise à jour peut ne plus être lisible : il est alors ignoré, et retéléchargé à la synchronisation suivante.

## Sources

Consultées le 31/10/2026 et le 02/11/2026 :

- [Listen offline](https://support.spotify.com/us/article/listen-offline/) (aide Spotify)
- [Listen To Deezer Offline](https://support.deezer.com/hc/en-gb/articles/115003884605-Listen-To-Deezer-Offline) (aide Deezer)
- [Store key-value data on disk](https://docs.flutter.dev/cookbook/persistence/key-value) (documentation Flutter)
- [Read and write files](https://docs.flutter.dev/cookbook/persistence/reading-writing-files) (documentation Flutter)
- [Persist data with SQLite](https://docs.flutter.dev/cookbook/persistence/sqlite) (documentation Flutter)
- [path_provider](https://pub.dev/packages/path_provider) (pub.dev)

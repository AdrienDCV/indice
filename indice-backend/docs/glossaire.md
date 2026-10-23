I# Glossaire

Vocabulaire utilisé dans le projet Indice : termes financiers, termes propres à l'application, et termes techniques du backend.

Les identifiants de code sont en anglais ; leur équivalent français est indiqué entre parenthèses lorsque c'est utile.

---

## 1. Finance

| Terme | Définition |
|---|---|
| **ETF** (*Exchange Traded Fund*, fonds indiciel coté) | Fonds qui réplique la performance d'un **indice** et s'échange en bourse comme une action. Acheter une part d'ETF MSCI World revient à investir d'un coup dans plus de 1 000 entreprises. |
| **Indice** | Panier d'actifs représentatif d'un marché, calculé par un fournisseur (MSCI, S&P, Stoxx…). Ex. : CAC 40, S&P 500, MSCI World. Un ETF « suit » un indice. |
| **ISIN** (*International Securities Identification Number*) | Code international unique de 12 caractères qui identifie un titre financier (ex. `US78462F1030` pour SPY). Il n'est **pas utilisé** par Indice : il est réservé à une option payante chez Twelve Data. Les ETF sont identifiés par leur **ticker**. |
| **Ticker** (code mnémonique) | Code court qui identifie un titre **sur une place de cotation** (ex. `CW8`). Un même ETF peut avoir des tickers différents selon la place ou la devise. |
| **Place de cotation** (*exchange*) | Marché boursier sur lequel un titre s'échange. Les ETF d'Indice sont cotés aux États-Unis (`NYSE`, `NASDAQ`), seuls couverts par l'offre gratuite de Twelve Data. |
| **Devise** (*currency*) | Monnaie dans laquelle un ETF est coté sur une place (ex. `EUR`). À distinguer des devises des actifs qu'il contient : un ETF coté en euros peut détenir des actions américaines, ce qui crée un **risque de change**. |
| **Frais courants** (*TER*, *Total Expense Ratio*) | Frais annuels prélevés par le gestionnaire de l'ETF, exprimés en pourcentage de l'encours (ex. 0,38 %/an). Critère de comparaison clé sur le long terme. |
| **Encours** (*AUM*, *Assets Under Management*) | Montant total investi dans un ETF. Un encours élevé est en général signe de liquidité et de pérennité. |
| **Réplication** | Méthode par laquelle l'ETF suit son indice : **physique** (il détient réellement les titres de l'indice) ou **synthétique** (il passe par un contrat d'échange avec une banque, appelé *swap*). |
| **Écart de suivi** (*tracking error*) | Écart entre la performance de l'ETF et celle de son indice. Plus il est faible, plus l'ETF suit fidèlement l'indice. |
| **Capitalisant / distribuant** | Un ETF **capitalisant** réinvestit automatiquement les dividendes ; un ETF **distribuant** les verse aux porteurs. |
| **UCITS** (OPCVM en français) | Cadre réglementaire européen qui encadre les fonds vendus au grand public (diversification minimale, contrôle des risques). Mention fréquente dans le nom des ETF européens. |
| **PEA** (Plan d'Épargne en Actions) | Enveloppe fiscale française avantageuse après 5 ans. Seuls certains ETF y sont **éligibles**. |
| **Diversification** | Répartition d'un investissement sur de nombreux actifs, secteurs ou pays pour réduire le risque. C'est le principal intérêt pédagogique des ETF. Elle n'est efficace que si les actifs ne baissent pas tous en même temps : c'est ce que mesure la **corrélation**. |
| **Jour de bourse** | Jour où le marché est ouvert. Il y en a environ **252 par an** aux États-Unis (hors week-ends et jours fériés), d'où environ 1 260 cours sur 5 ans. |
| **Clôture ajustée** (`ClosingPrice.adjustedClose`) | Cours de clôture d'un jour de bourse, corrigé des divisions d'actions **et des dividendes** (`adjust=all` chez Twelve Data). Il permet de comparer les cours dans le temps comme si les dividendes avaient été réinvestis. |
| **Rendement total** | Rendement calculé sur des clôtures ajustées, donc **dividendes réinvestis**. C'est la seule façon de comparer équitablement un ETF qui verse des dividendes et un ETF qui n'en verse pas. |
| **Rendement sur N ans** | `dernière clôture / clôture de référence − 1`, où la clôture de référence est la dernière clôture située au moins N ans avant la dernière clôture (si cette date tombe un jour de fermeture, on prend le jour de bourse précédent). |
| **Rendement annualisé** (CAGR) | Rendement moyen par an sur une période : `(1 + rendement sur N ans)^(1/N) − 1`. Ex. un ETF qui double en 5 ans a un rendement annualisé d'environ 14,9 %. Dans la comparaison, la durée réelle est utilisée (`nombre de jours / 365,25` années), et aucun rendement n'est annualisé sur moins d'un an. |
| **Volatilité annualisée** | Écart-type des rendements journaliers sur 1 an, multiplié par √252. Elle mesure l'amplitude habituelle des variations : plus elle est élevée, plus l'ETF est risqué. |
| **Perte maximale** (*max drawdown*) | Plus forte baisse entre un sommet et le creux qui le suit, sur 5 ans (ex. −24,5 % pour SPY entre janvier et octobre 2022). Elle montre concrètement ce qu'un investisseur aurait pu perdre au pire moment. |
| **Fourchette sur 52 semaines** | Plus bas et plus haut des clôtures sur 1 an, et **position** du dernier cours dans cette fourchette, entre 0 (au plus bas) et 1 (au plus haut). |
| **Historique des clôtures** (`ClosingPriceHistory`) | Objet métier qui regroupe les clôtures ajustées d'un ETF sur 5 ans et calcule tous les indicateurs de la fiche détaillée et de la comparaison, ainsi que la série de cours de la fiche détaillée (`pricePoints`). Les cours sont stockés dans la table `etf_closing_price` et rafraîchis au plus une fois par jour (`ClosingPriceService`). |
| **Période commune** (`commonPeriodWith`) | Dates où deux ETF ont tous les deux une clôture. Une comparaison porte toujours sur cette période, pour que les chiffres des deux ETF soient comparables. Elle doit couvrir au moins 1 an. |
| **Point de cours** (`PricePoint`, `pricePoints`) | Clôture ajustée d'un jour de bourse, avec sa date et sa **variation depuis le début de l'historique** (`clôture / première clôture − 1`). La fiche détaillée en expose un par jour de bourse, sur au plus 5 ans. La comparaison en expose aussi un par jour de bourse pour chaque ETF, calculés sur la période commune : la variation part alors de 0 au premier jour de cette période. |
| **Taux sans risque** | Rendement d'un placement considéré comme sûr (ex. emprunt d'État à court terme). Il sert de référence au ratio de Sharpe. Twelve Data ne le fournit pas. |
| **Normes GIPS** (*Global Investment Performance Standards*) | Normes internationales du CFA Institute sur la présentation des performances des gestionnaires de fonds. Indice en reprend une règle : un rendement mesuré sur **moins d'un an n'est jamais annualisé**, car l'extrapoler à une année entière donnerait un chiffre trompeur (ex. +5 % en un mois deviendrait environ +80 % « par an »). |
| **Ratio de Sharpe** | `(rendement − taux sans risque) / volatilité` : rendement obtenu, au-delà d'un placement sûr, par unité de risque (William F. Sharpe). |
| **Ratio rendement/risque** (`returnToRiskRatio`) | `rendement annualisé / volatilité annualisée`. Version simplifiée du ratio de Sharpe, **sans taux sans risque** : elle ne porte donc pas ce nom. Elle ne désigne pas le « meilleur » ETF : chacun juge selon sa tolérance aux variations. |
| **Corrélation** (`correlationWith`) | Coefficient de Pearson entre les **rendements journaliers** de deux ETF, entre −1 et 1. Proche de 1 : ils montent et baissent les mêmes jours, et se protègent peu l'un l'autre. Proche de 0 : leurs mouvements sont peu liés. Négative : ils évoluent plutôt en sens inverse. |
| **Volatilité** | Ampleur des variations du prix d'un actif. Une volatilité élevée signifie un risque plus élevé, à la hausse comme à la baisse. |
| **Rendement / performance** | Gain ou perte d'un investissement sur une période, exprimé en pourcentage. Les performances passées ne préjugent pas des performances futures. |
| **ETF à effet de levier** (*leveraged*) | ETF qui multiplie la variation **quotidienne** d'un indice (ex. ×2). Produit spéculatif, inadapté aux débutants et à une détention longue. |
| **ETF inverse** (*short*, *bear*) | ETF qui évolue à l'opposé de son indice (ex. −1×) : il gagne quand l'indice baisse. Produit spéculatif. |
| **Portefeuille** | Ensemble des placements détenus par un investisseur. Dans Indice, il est uniquement **fictif** (module *Construire*). |

---

## 2. Application Indice

| Terme | Définition |
|---|---|
| **Module Apprendre** | Ressources pédagogiques (textes, images, vidéos) sur l'investissement et les ETF. |
| **Module Comparer** | Fiches détaillées d'ETF et comparaison sur des indicateurs clés. Ce n'est **pas** un conseil en investissement. |
| **Module Construire** | Construction d'un portefeuille fictif à but pédagogique. Optionnel, prévu plus tard. |
| **Ressource pédagogique** (`RessourcePedagogique`) | Contenu du module *Apprendre*. Peut contenir un **média**. |
| **Média** (`Media`) | Image ou vidéo associée à une ressource. Son type (`MediaType` : `IMAGE` ou `VIDEO`) est déduit de l'extension du fichier ou du lien. |
| **Catalogue d'ETF** (`EtfCatalog`) | Liste des ETF proposés dans l'application, stockée en base et exposée par `GET /api/etfs`. |
| **Comparaison d'ETF** (`EtfComparison`) | Mise en regard de deux ETF du catalogue sur leur période commune : indicateurs de chacun (`Performance`), séries de cours (`pricePoints`) et corrélation. Exposée par `GET /api/etfs/compare?etfA=...&etfB=...`. Elle ne désigne aucun gagnant. |
| **ETF A / ETF B** (`etfA`, `etfB`) | Les deux côtés d'une comparaison, avec le vocabulaire de l'application mobile. Les clés d'erreur indiquent le côté concerné (ex. `error.etfs.etf-a-insufficient-data`). |
| **Synchronisation** | Mise à jour du catalogue à partir de l'annuaire des ETF de Twelve Data. Elle a lieu **à la demande**, lorsqu'un utilisateur consulte un catalogue périmé. Les ETF connus sont rafraîchis, les ETF sélectionnés nouveaux sont ajoutés, et ceux absents de la réponse sont retirés. |
| **Date de synchronisation** (`fetchedAt`) | Date de la dernière synchronisation réussie d'un ETF. Celle du catalogue est la plus récente de ses ETF. |
| **Durée de validité** (`TTL`, *Time To Live*) | Durée pendant laquelle le catalogue est considéré comme à jour : 7 jours. |
| **Catalogue périmé** (`EtfCatalog.isStale`) | Catalogue vide, ou dont la dernière synchronisation date de plus de 7 jours. Déclenche un appel à Twelve Data. |
| **Données obsolètes** (`stale` dans la réponse) | Indique que le catalogue renvoyé est périmé **et** que sa synchronisation vient d'échouer : les données affichées peuvent être anciennes. |
| **ETF sélectionnés** (`etf.catalog.selected-tickers`) | Liste de tickers choisie à la main pour leur intérêt pédagogique, définie dans `application.yaml`. Le catalogue contient exactement ceux de ces ETF que Twelve Data renvoie. |

---

## 3. Sources de données externes

| Terme | Définition |
|---|---|
| **Twelve Data** | Fournisseur de données financières utilisé pour le catalogue (offre gratuite, ETF américains uniquement). EODHD et Alpha Vantage ont été étudiés puis écartés (voir `docs/plans/plan-implementation-catalogue-twelve-data.md`). |
| **Ticker** (*symbol*) | Code court d'un ETF sur sa place de cotation (ex. `SPY`). C'est l'**identifiant** des ETF dans Indice, et le champ `symbol` des réponses de Twelve Data. |
| **Annuaire des ETF** (`/etfs`) | Endpoint de Twelve Data qui renvoie, en un seul appel (1 crédit), tous les ETF d'un pays avec leur nom, leur devise et leur place. |
| **Quota** | Nombre d'appels autorisés par Twelve Data : 800 crédits par jour et 8 par minute en offre gratuite. Chaque synchronisation du catalogue consomme 1 crédit. |
| **Token d'API** (`twelvedata.api-token`) | Clé secrète qui authentifie les appels à Twelve Data, envoyée dans l'en-tête `Authorization`. Ne doit apparaître ni dans un fichier versionné ni dans les logs. |

---

## 4. Architecture technique

| Terme | Définition |
|---|---|
| **Architecture 3-tiers** | Découpage en trois couches : **présentation** (controllers, DTOs), **métier** (services, objets métier) et **accès aux données** (repositories, entités, clients). |
| **Domaine** | Notion métier qui donne son nom à un package de premier niveau (`etf`, `resource`). |
| **Controller** (`controllers/`) | Point d'entrée HTTP. Reçoit une requête, convertit les DTOs ⇄ objets métier, délègue à un service et renvoie un DTO. Aucune logique métier. |
| **Service** (`services/`) | Coordonne un cas d'usage : charge les données, demande aux objets métier d'agir, enregistre et renvoie le résultat sous forme d'objet métier (jamais de DTO). |
| **Objet métier** (`models/`) | Classe Kotlin immuable (`data class`) qui porte la logique propre à une notion (ex. `Etf`, `EtfCatalog`). Sans annotation Spring, JPA ou Jackson. |
| **Identifiant technique** (`id`) | UUID généré à la création d'un objet métier, qui sert de clé primaire en base. Interne au backend, il ne change jamais, contrairement aux données externes comme le ticker. |
| **Entité** (`entities/`, suffixe `Entity`) | Classe JPA qui reflète une table de la base. Aucune logique. |
| **DTO** (*Data Transfer Object*, suffixe `Dto`) | Structure de transport de données, sans logique : entrée ou sortie de l'API Indice (`Request` / `Response`), ou format d'une API externe. Rangé dans `dtos/requests/` (corps de requête) ou `dtos/responses/` (corps de réponse). |
| **Mapper** (`mappers/`) | Fonctions d'extension qui convertissent DTO ⇄ objet métier ⇄ entité. Jamais de conversion directe DTO ⇄ entité. |
| **Repository** (`repositories/`) | Interface Spring Data qui lit et écrit les entités en base. |
| **Client** (`clients/`) | Classe qui appelle une API externe (ex. `TwelveDataClient`). |
| **Exception métier** (`BusinessException`) | Erreur prévue par les règles de l'application (ex. ETF introuvable). Elle porte son statut HTTP et une clé de message, et elle est convertie en réponse HTTP par `ExceptionController`. |
| **Exception technique** | Erreur d'infrastructure (API externe indisponible, réseau…). Gérée dans le service lorsque c'est possible ; sinon renvoyée au client comme une erreur 500 générique. |
| **Clé de message** | Identifiant d'un message d'erreur (ex. `error.etfs.etf-not-found`) renvoyé par l'API à la place d'une phrase. L'application mobile le traduit pour l'affichage. |
| **ControllerAdvice** (`ExceptionController`) | Composant Spring qui intercepte les exceptions de tous les controllers et les traduit en réponses HTTP au format uniforme (`ErrorResponseDto`). |
| **Pagination** | Découpage d'une liste en pages (`page`, `size`, `sort`) faite en base de données. Tout endpoint de listing de l'API est paginé, et la réponse indique `totalElements` et `totalPages`. |
| **Migration Flyway** | Script SQL versionné (`V<n>__<description>.sql`) qui fait évoluer le schéma de la base. Une migration déjà appliquée n'est jamais modifiée. |
| **Transaction** (`@Transactional`) | Ensemble d'opérations en base validées ou annulées ensemble. |

---

## 5. Principes de conception

| Terme | Définition |
|---|---|
| **SOLID** | Cinq principes de conception orientée objet : responsabilité unique, ouvert/fermé, substitution de Liskov, ségrégation des interfaces, inversion des dépendances. |
| **KISS** (*Keep It Simple, Stupid*) | Préférer la solution la plus simple qui répond au besoin. |
| **YAGNI** (*You Aren't Gonna Need It*) | Ne pas implémenter ce qui n'est pas demandé « au cas où ». |
| **DRY** (*Don't Repeat Yourself*) | Éviter la duplication de logique, sans factoriser prématurément. |
| **Tell, don't ask** | Demander à un objet d'agir (`etf.refreshedFrom(source)`) plutôt que de lire son état pour décider à sa place. |
| **Immuabilité** | Un objet n'est jamais modifié après sa création : une « modification » produit une nouvelle instance via `copy()`. |
| **Invariant** | Règle toujours vraie pour un objet valide (ex. un `Etf` a un ticker non vide), vérifiée à la construction. |
| **Given / When / Then** | Structure d'un test : contexte initial, action testée, résultat attendu. |
| **Mock** | Faux objet qui remplace une dépendance dans un test (bibliothèque **MockK**). |

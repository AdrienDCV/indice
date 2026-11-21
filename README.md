# Indice

Investir paraît souvent compliqué quand on débute. **Indice** est une application mobile qui aide les étudiants et les jeunes actifs à comprendre l'investissement, en particulier les ETF, ces fonds qui suivent un indice boursier.

Elle s'organise autour de deux espaces :

- **Apprendre** : des articles et des vidéos pour découvrir les notions de base, à son rythme ;
- **Comparer** : un catalogue d'ETF, une fiche par ETF et une comparaison côte à côte de leurs frais, performances et risques.

Les ETF et les ressources ajoutés en favoris restent consultables hors connexion.

Indice reste un outil pédagogique : l'application ne réalise aucune transaction et ne donne aucun conseil en investissement. Elle explique et compare, sans jamais recommander.

## Comment c'est construit

Le projet se compose de deux applications :

- **`indice-backend/`**, l'API qui porte toute la logique et les calculs : Kotlin, Spring Boot 4 et PostgreSQL 17. Les données de marché proviennent de l'API Twelve Data ;
- **`indice_mobile/`**, l'application Flutter, qui affiche les données reçues de l'API.

## Avant de commencer

Vous aurez besoin de :

- Java 25 ;
- Docker, démarré ;
- Flutter 3.47 ou plus récent, avec un simulateur iOS ou un émulateur Android.

## Configurer le backend

Le backend lit ses paramètres locaux, dont la clé de l'API Twelve Data, dans `indice-backend/src/main/resources/application.yaml`.

Si vous avez reçu le projet sous forme d'archive, ce fichier est déjà en place : vous pouvez passer directement au lancement. Sinon, créez-le avec votre propre clé (un compte gratuit sur [twelvedata.com](https://twelvedata.com) suffit) :

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/indicedb
    username: admin
    password: admin

twelvedata:
  api-token: <votre-clé-twelve-data>
```

## Lancer le projet

Ouvrez un simulateur ou un émulateur iOS ou Android, puis lancez depuis la racine du projet :

```bash
./start.sh
```

Le script s'occupe de tout : il démarre la base de données, puis l'API, puis l'application mobile. Pour quitter, tapez `q` dans le terminal : l'API s'arrête en même temps.

Sur un émulateur Android, remplacez `localhost` par `10.0.2.2` dans `indice_mobile/.env`.

### Préférer un lancement manuel

```bash
# Backend
cd indice-backend
docker compose up -d
./mvnw spring-boot:run -Dspring-boot.run.profiles=local

# Mobile, dans un autre terminal
cd indice_mobile
echo "API_BASE_URL=http://localhost:8080/api" > .env
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Lancer les tests

```bash
cd indice-backend && ./mvnw clean test       # avec la base Docker démarrée
cd ../indice_mobile && flutter test
```

# Indice Mobile

Application Flutter d'Indice. Elle affiche les données de l'API REST `../indice-backend`.

## Démarrer

1. Lancer l'API backend (voir `../indice-backend`).
2. Copier `.env.example` en `.env.local` et renseigner l'URL de l'API, context path `/api` compris :
   - simulateur iOS : `API_BASE_URL=http://localhost:8080/api`
   - émulateur Android : `API_BASE_URL=http://10.0.2.2:8080/api`

   Sans `.env.local`, l'application ne compile pas. Ce fichier est embarqué dans l'application : il ne contient jamais de secret.
3. Installer les dépendances et générer le code :

   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Lancer l'application : `flutter run`.

## Vérifier

```bash
flutter analyze
flutter test
```

Conventions du projet : `CLAUDE.md`.

# Lupus Flutter starter

Ce dossier contient une première base Flutter pour les écrans visibles dans les références :
- 7 écrans d'onboarding (un `PageView`)
- Écran d'accueil Lupus+
- Connexion
- Création de compte
- Type de compte

## Installation

1. Crée un projet Flutter nommé `lupus_app`.
2. Remplace le dossier `lib` du projet par le dossier `lib` fourni ici.
3. Copie le dossier `assets` à la racine du projet.
4. Dans `pubspec.yaml`, ajoute :

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

5. Exécute :

```bash
flutter pub get
flutter run
```

Les illustrations ont été recadrées à partir des captures de référence fournies. Les écrans sont une première implémentation fonctionnelle de navigation et de mise en page ; les tailles et espacements devront être ajustés sur ton appareil pour obtenir une correspondance pixel par pixel.

Les formulaires sont visuels pour le moment : l'authentification réelle, Firebase, les validations, les comptes médecin/patient et les appels vidéo seront ajoutés dans les étapes suivantes.

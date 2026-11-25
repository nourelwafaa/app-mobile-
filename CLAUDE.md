# Creative Lupus+ — instructions pour Claude Code

Application mobile de suivi pour les patients atteints de lupus (projet de Master 2, ISII).
Je (Nour) m'occupe du **backend** et des **connexions front ↔ back**. Mes 2 binômes font les écrans Flutter.

Réponds-moi en français, simplement, étape par étape. Donne-moi les commandes à copier-coller.

## Stack

- **Backend** : Node.js + Express, port 3001 (`backend/`)
- **Base** : PostgreSQL 18, base `creative_lupus`, gérée avec pgAdmin
- **Frontend** : Flutter (`frontend/`), testé sur un émulateur Android (Pixel 6)
- **Auth** : JWT (`jsonwebtoken`, 7 jours) + `bcryptjs`

## Lancer le projet

```
# Terminal 1 : backend
cd backend
npm run dev

# Terminal 2 : app (émulateur Android allumé)
cd frontend
flutter run
```

Depuis l'émulateur, le backend est joignable sur `http://10.0.2.2:3001/api` (géré dans `frontend/lib/core/api_client.dart`).

## Structure

```
app-mobile-/
├── API.md                  # doc des API pour l'équipe front : à mettre à jour à chaque nouvelle API
├── backend/
│   ├── server.js
│   ├── config/db.js        # Pool pg ; les DATE sont renvoyées en texte "AAAA-MM-JJ" (types.setTypeParser(1082))
│   ├── middleware/authMiddleware.js   # verifierToken, autoriserRoles("patient" | "medecin")
│   ├── controllers/        # authController, patientController, suiviController, traitementController
│   ├── routes/             # authRoutes (/api/auth), patientRoutes (/api/patients), medecinRoutes (/api/medecin)
│   └── database/           # 01 à 05 *.sql : le schéma complet (23 tables) ; 06_index_prises.sql (unicité des prises)
└── frontend/lib/
    ├── core/api_client.dart        # ApiClient (get/post/put, token Bearer, erreurs → ApiException)
    ├── providers/auth_provider.dart # kDemoMode = false : l'auth utilise le vrai backend
    ├── models/
    ├── services/           # MON dossier : appels API (suivi_service.dart, traitement_service.dart…) ; medecin_service.dart = fausses données des binômes
    ├── screens/            # écrans patient + auth (binômes)
    └── features/medecin/   # écrans médecin (binômes)
```

## Règles du projet

- L'app doit correspondre à la présentation Canva : ne pas ajouter de fonctionnalités inventées.
- **Fonctionnalités abandonnées** : connexion Google/Facebook, consultation vidéo, rôles proche/pharmacien/étudiant/autre. Seuls les rôles `patient` et `medecin` existent.
- **Messagerie** : uniquement entre un médecin et un patient qu'il suit (`suivi_medical`). Pas de chat entre patients.
- **Méthode pour chaque fonctionnalité** :
  1. lire d'abord l'écran Flutter des binômes et utiliser **exactement** leurs noms de champs ;
  2. créer l'API (contrôleur + route), protégée par `verifierToken` + `autoriserRoles` ;
  3. tester avec Postman ;
  4. ajouter la section dans `API.md` ;
  5. brancher l'écran : service dans `lib/services/`, modèle dans `lib/models/`, et garder leur design tel quel (on remplace seulement les fausses données).
- Champs JSON en `snake_case` (`nom_complet`, `date_naissance`…), dates en `AAAA-MM-JJ`, chaque réponse a un champ `message`.
- Les nombres `NUMERIC` sont renvoyés avec `::float` (sinon `pg` les renvoie en texte).
- Ne jamais commiter `backend/.env` ni les fichiers générés par Flutter (`frontend/linux|macos|windows/flutter/generated_*`, `pubspec.lock` modifié par `pub get`).
- **Git** : jamais `git add .`. Ajouter seulement les fichiers voulus (`git add backend API.md frontend/lib/...`). Avant un `git pull` : `git restore frontend` pour jeter les fichiers générés. Messages de commit en français.
- Les binômes travaillent sur des branches `feature/...` qu'ils fusionnent dans `main`.

## Comptes de test

- Patient : `sarah@test.com` / `123456`
- Médecin : `medecin@test.com` / `123456`

## Avancement

- [x] Base de données : 23 tables (`users`, `patients`, `professionnels`, `suivi_medical`, `suivi_quotidien`, `symptomes`, `journal_sante`, `alertes`, `traitements`, `rappels_medicament`, `prises_medicament`, `rendez_vous`, `analyses`, `documents_medicaux`, `acces_dossier`, `etablissements`, `messages`, `publications`, `commentaires`, `conseils`, `lupia_messages`, `notifications`, `reset_mot_de_passe`)
- [x] Séance 1 : `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/patients/me`, `PUT /api/patients/me/infos` — branchés dans l'app
- [x] Séance 2 : `POST /api/patients/me/suivi`, `GET /api/patients/me/suivi/aujourdhui`, `GET /api/patients/me/stats?periode=7|30|90` — branchés (`suivi_screen.dart`, `stats_screen.dart`). Douleur ≥ 8 → alerte dans `alertes`.
- [x] Séance 3 : `GET/POST /api/patients/me/traitements`, `GET /api/patients/me/prises/aujourdhui`, `POST /api/patients/me/prises`, `GET/POST /api/medecin/patients/:patientId/traitements` (patient suivi dans `suivi_medical`). Heures de rappel automatiques selon `fois_par_jour` (1 → 08:00 ; 2 → 08:00, 20:00 ; 3 → 08:00, 14:00, 20:00…). Branchés côté patient : `rappels_screen.dart` (onglet Médicaments), carte « Aujourd'hui » de `home_screen.dart`, `AddTraitementPage.patient()`. **Côté médecin, `AddTraitementPage` et la fiche patient restent sur `medecin_service.dart` : à brancher en séance 6.**
- [ ] **Séance 4 (prochaine)** : rendez-vous, analyses, agenda (`features/medecin/agenda/`, `screens/patient/agenda_screen.dart`, onglets Rendez-vous / Analyses de `rappels_screen.dart`, ligne RDV de l'accueil)
- [ ] Séance 5 : dossier médical + partage (`add_document_page.dart`, `dossier_screen.dart`)
- [ ] Séance 6 : espace médecin réel (ajout de patient, liste, fiche, alertes, tableau de bord) — remplacer les fausses données de `medecin_service.dart` (dont les traitements : API déjà prêtes, voir API.md §11)
- [ ] Séance 7 : messagerie médecin ↔ patient
- [ ] Séance 8 : recherche, communauté, conseils, LupIA, notifications
- [ ] Séance 9 : mot de passe oublié
- [ ] Séance 10 : mise en ligne + tests finaux

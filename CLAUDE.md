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
│   ├── controllers/        # authController, patientController, suiviController, traitementController, agendaController, dossierController, medecinController, messagesController, demandesController, notificationsController
│   ├── routes/             # authRoutes (/api/auth, limite de tentatives), patientRoutes (/api/patients), medecinRoutes (/api/medecin)
│   ├── utils/validation.js # règles communes : email, téléphone (chiffres seulement), mot de passe, date de naissance
│   └── database/           # 01 à 05 *.sql : le schéma complet (23 tables) ; 06_index_prises.sql (unicité des prises) ; 07_documents.sql (fichier facultatif + partage automatique) ; 08_securite_comptes.sql (téléphones normalisés) ; 09_demandes_suivi.sql (consentement du patient) ; 10_notifications.sql (notifications du médecin)
└── frontend/lib/
    ├── core/api_client.dart        # ApiClient (get/post/put, token Bearer, erreurs → ApiException)
    ├── providers/auth_provider.dart # kDemoMode = false : l'auth utilise le vrai backend
    ├── models/
    ├── services/           # MON dossier : appels API (suivi_service.dart, traitement_service.dart, agenda_service.dart, dossier_service.dart, espace_medecin_service.dart, messages_service.dart…) ; medecin_service.dart = fausses données restantes + les ValueNotifier qui rechargent les écrans médecin
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
- Les nouveaux comptes doivent avoir un mot de passe de 8 caractères minimum avec lettres et chiffres (ex. `Lupus2026`) ; les anciens comptes gardent `123456`.

## Avancement

- [x] Base de données : 23 tables (`users`, `patients`, `professionnels`, `suivi_medical`, `suivi_quotidien`, `symptomes`, `journal_sante`, `alertes`, `traitements`, `rappels_medicament`, `prises_medicament`, `rendez_vous`, `analyses`, `documents_medicaux`, `acces_dossier`, `etablissements`, `messages`, `publications`, `commentaires`, `conseils`, `lupia_messages`, `notifications`, `reset_mot_de_passe`)
- [x] Séance 1 : `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/patients/me`, `PUT /api/patients/me/infos` — branchés dans l'app
- [x] Séance 2 : `POST /api/patients/me/suivi`, `GET /api/patients/me/suivi/aujourdhui`, `GET /api/patients/me/stats?periode=7|30|90` — branchés (`suivi_screen.dart`, `stats_screen.dart`). Douleur ≥ 8 → alerte dans `alertes`.
- [x] Séance 3 : `GET/POST /api/patients/me/traitements`, `GET /api/patients/me/prises/aujourdhui`, `POST /api/patients/me/prises`, `GET/POST /api/medecin/patients/:patientId/traitements` (patient suivi dans `suivi_medical`). Heures de rappel automatiques selon `fois_par_jour` (1 → 08:00 ; 2 → 08:00, 20:00 ; 3 → 08:00, 14:00, 20:00…). Branchés côté patient : `rappels_screen.dart` (onglet Médicaments), carte « Aujourd'hui » de `home_screen.dart`, `AddTraitementPage.patient()`. **Côté médecin, `AddTraitementPage` et la fiche patient restent sur `medecin_service.dart` : à brancher en séance 6.**
- [x] Séance 4 : le **médecin crée** les rendez-vous et les analyses, le **patient consulte** seulement. `GET /api/patients/me/rendez-vous`, `GET /api/patients/me/analyses`, `GET /api/medecin/patients` (version simple), `GET/POST /api/medecin/rendez-vous`, `PUT /api/medecin/rendez-vous/:id/statut`, `POST /api/medecin/analyses` (pas encore d'écran : Postman). Branchés : agenda patient, onglets Rendez-vous / Analyses de `rappels_screen.dart`, ligne RDV de l'accueil, `AgendaPage` + `NewRdvPage` médecin (vrais patients aussi dans les actions rapides et la fiche). Les boutons « + Ajouter un rendez-vous » côté patient seront supprimés par une binôme.
- [x] Séance 5 : dossier médical. Le **médecin ajoute** les documents (titre, type, date ; **pas encore de vrai fichier**, `fichier_url` facultatif), le **patient consulte**. Un médecin qui suit un patient a accès à son dossier (`acces_dossier`). `GET /api/patients/me/documents`, `GET /api/patients/me/partages`, `GET/POST /api/medecin/patients/:patientId/documents`. Branchés : `dossier_screen.dart` (documents + « Partagé avec »), `AddDocumentPage`, onglet Documents de la fiche patient. Le bouton « Ajouter un document » côté patient sera supprimé par une binôme.
- [x] Séance 6 : espace médecin réel. `medecinController.js` : `GET /api/medecin/patients` (complet : alerte en cours, douleur 7 jours, RDV cette semaine), `GET /api/medecin/patients/:id`, `GET /api/medecin/patients/recherche?identifiant=`, `POST /api/medecin/patients` (aujourd'hui : envoie une demande de suivi, voir « Sécurité des comptes »), `GET /api/medecin/alertes`, `PUT /api/medecin/alertes/:id/traitee`, `GET /api/medecin/accueil` (« amélioration moyenne » = baisse de la douleur moyenne, 7 j vs 7 j précédents), `GET/PUT /api/medecin/profil`. Branchés : patients, ajout, choisir un patient, fiche (+ traitements/prescrire), alertes, accueil, profil (`espace_medecin_service.dart`). **Restent dans `medecin_service.dart`** : messages (séance 7), notifications (séance 8), photo de profil (locale), et les `ValueNotifier` (`patientsChanged`, `rdvChanged`, `alertesChanged`…) qui servent à recharger les écrans.
- [x] Séance 7 : messagerie médecin ↔ patient (`messagesController.js`), uniquement si le médecin suit le patient. Patient : `GET /api/patients/me/medecins`, `GET/POST /api/patients/me/messages/:medecinId` ; médecin : `GET /api/medecin/conversations`, `GET/POST /api/medecin/messages/:patientId` ; `messages_non_lus` ajouté à `GET /api/medecin/accueil`. JSON `texte` ↔ colonne `contenu`. Pas de temps réel : la discussion ouverte se recharge toutes les 5 s. **Ajout validé par Nour** : icône 💬 + page « Messages » côté patient (`messages_screen.dart`, `chat_screen.dart` refait), même design que les écrans médecin. « Trouver un pro » (fausse liste) : écriture désactivée.
- [x] Sécurité des comptes : inscription validée côté serveur (`utils/validation.js` : mot de passe 8-72 caractères avec lettres + chiffres, email, téléphone en chiffres, date de naissance), connexion par email ou téléphone, limite de tentatives (`express-rate-limit` : 10 échecs / 15 min, 20 inscriptions / heure → 429). **Consentement du patient** : `POST /api/medecin/patients` envoie une **demande** (`demandes_suivi`) ; la recherche ne montre que le nom tant que le patient n'a pas accepté. Patient : `GET /api/patients/me/demandes`, `PUT /api/patients/me/demandes/:id` (`accepter` → crée `suivi_medical` + `acces_dossier`, `refuser`). Branché : bandeau « Dr X souhaite vous suivre » sur l'accueil patient, bouton « Envoyer une demande de suivi » côté médecin.
- [x] Écrans patient de la binôme (PR « ecrans-binome ») : nouvel accueil, photo de profil locale, « + Ajouter un document » dans Rapports → Analyses (**local, pas encore envoyé au serveur**). Plus aucun bouton « Ajouter un rendez-vous » côté patient. `file_picker` en version 10 (la 8 ne compile pas avec Android 36).
- [x] Séance 8a : notifications du médecin (`notificationsController.js`). Créées automatiquement par le serveur à chaque `GET /api/medecin/notifications` ou `GET /api/medecin/accueil` : message d'un patient suivi, alerte, RDV planifié qui commence dans moins de `rappel_minutes` (60 par défaut). Pas de doublon (`ref_id` + index unique). Lues toutes seules quand le message est lu ou l'alerte traitée. `PUT /api/medecin/notifications/:id/lue`, `PUT /api/medecin/notifications/lues`, `notifications_non_lues` dans l'accueil (point de la cloche). Branchés : `notifications_page.dart`, `home_header.dart`.
- [ ] **Séance 8 (suite)** : recherche, communauté, conseils, LupIA
- [ ] Séance 9 : mot de passe oublié
- [ ] Séance 10 : mise en ligne + tests finaux

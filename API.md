# Creative Lupus+ — Documentation des API

Ce fichier liste toutes les API du backend, pour l'équipe Flutter.
Il est mis à jour à chaque nouvelle API.

## Règles générales

- **Adresse du backend** : `http://10.0.2.2:3001` (émulateur sur le même PC) ou l'adresse ngrok donnée par Nour.
- Toutes les requêtes envoient du JSON : header `Content-Type: application/json`.
- **Toutes les API sauf `register` et `login` demandent le token** dans le header :
  `Authorization: Bearer <token>`
- Chaque réponse contient un champ `message` qu'on peut afficher à l'utilisateur.
- Dates au format `AAAA-MM-JJ` (ex : `2000-05-15`).

| Code | Signification |
| --- | --- |
| 200 / 201 | Succès |
| 400 | Champ manquant ou invalide |
| 401 | Pas connecté, token manquant ou expiré |
| 403 | Accès refusé (mauvais rôle) |
| 404 | Introuvable |
| 409 | Déjà existant (ex : email déjà utilisé) |
| 500 | Erreur serveur |

---

## 1. Inscription

`POST /api/auth/register` — pas de token

```json
{
  "nom_complet": "Sarah Benali",
  "email": "sarah@test.com",
  "telephone": "0555123456",
  "mot_de_passe": "123456",
  "date_naissance": "2000-05-15",
  "role": "patient"
}
```

- `role` : `patient` ou `medecin`
- `telephone` et `date_naissance` sont optionnels
- Mot de passe : **8 caractères minimum, au moins une lettre et un chiffre** (72 max)
- Email vérifié par le serveur ; nom de 2 à 150 caractères ; date de naissance réelle, pas dans le futur
- Téléphone enregistré avec **seulement les chiffres** (`"0661 23 45 67"` → `"0661234567"`), 8 à 15 chiffres
- Limite : 20 inscriptions par heure depuis un même appareil (**429** au-delà)
- L'écran « Créer un compte » et l'écran « Type de compte » sont séparés : garder les infos du 1er écran et appeler `register` après le choix du rôle.

Réponse **201** : `message`, `token`, `user`
Erreurs : **400** (champ manquant ou invalide), **409** (email ou téléphone déjà utilisé), **429** (trop d'inscriptions)

## 2. Connexion

`POST /api/auth/login` — pas de token

```json
{
  "identifiant": "sarah@test.com",
  "mot_de_passe": "123456"
}
```

- `identifiant` = email **ou** numéro de téléphone (espaces et tirets ignorés)
- Les comptes créés avant la séance de sécurité gardent leur ancien mot de passe

Réponse **200** : `message`, `token`, `user`
Erreurs : **401** (identifiant ou mot de passe incorrect), **429** (« Trop de tentatives de connexion. Réessayez dans 15 minutes. » : 10 échecs en 15 min)

👉 Garder le `token` dans l'app (ex : `shared_preferences`) et le supprimer à la déconnexion.

## 3. Profil du patient

`GET /api/patients/me` — token obligatoire, rôle patient

Réponse **200** :

```json
{
  "id": 1,
  "nom_complet": "Sarah Benali",
  "email": "sarah@test.com",
  "telephone": "0555123456",
  "date_naissance": "2000-05-15",
  "role": "patient",
  "photo": null,
  "age": 26,
  "sexe": "femme",
  "poids": 75,
  "taille": 178,
  "groupe_sanguin": "AB+"
}
```

Sert pour : la page Profil et « Bonjour Sarah » sur l'accueil. L'âge est calculé par le serveur.

## 4. Ajouter des informations

`PUT /api/patients/me/infos` — token obligatoire, rôle patient

```json
{
  "sexe": "femme",
  "poids": 75,
  "taille": 178,
  "groupe_sanguin": "AB+"
}
```

- Chaque champ est optionnel (on peut n'en envoyer qu'un).
- `sexe` : `homme` ou `femme`
- `groupe_sanguin` : `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`

Réponse **200** : `"message": "Informations enregistrées"` + `infos`
Erreur : **400** (valeur invalide)

## 5. Suivi du jour

`POST /api/patients/me/suivi` — token obligatoire, rôle patient

```json
{
  "douleur": 6,
  "fatigue": 7,
  "humeur": 5,
  "sommeil_heures": 7.5,
  "remarque": "Un peu fatiguée",
  "symptomes": ["Douleurs articulaires", "Fatigue"]
}
```

- `douleur`, `fatigue`, `humeur` : obligatoires, de 0 à 10
- Un seul suivi par jour : renvoyer remplace celui du jour
- Douleur ≥ 8 → une alerte est créée pour le médecin

Réponse **201** : `"message": "Suivi enregistré"` + `suivi`

`GET /api/patients/me/suivi/aujourdhui` → `{ "suivi": {...} }` ou `{ "suivi": null }` si pas encore fait aujourd'hui (pour pré-remplir l'écran)

## 6. Statistiques

`GET /api/patients/me/stats?periode=7` (ou 30, 90) — token obligatoire, rôle patient

```json
{
  "periode": 7,
  "jours": [{ "date": "2026-11-19", "douleur": 9, "fatigue": 7, "humeur": 4, "sommeil_heures": 6 }],
  "moyennes": { "douleur": 9, "fatigue": 7, "humeur": 4, "sommeil_heures": 6, "jours_remplis": 1 },
  "symptome_frequent": { "nom": "Douleurs articulaires", "jours": 1 },
  "tendance_fatigue": { "actuelle": 7, "precedente": null, "evolution": null }
}
```

- `jours` : une ligne par jour de la période, valeurs à `null` si pas de suivi ce jour-là
- `evolution` : `baisse`, `hausse`, `stable`, ou `null` s'il n'y a pas assez de données
## 7. Traitements du patient

`GET /api/patients/me/traitements` — token obligatoire, rôle patient

Réponse **200** :

```json
{
  "message": "Liste des traitements",
  "traitements": [
    {
      "id": 2,
      "nom": "Plaquenil",
      "dosage": "200 mg",
      "fois_par_jour": 2,
      "debut": "2026-11-01",
      "fin": null,
      "prescrit_par": null,
      "actif": true,
      "heures": ["08:00", "20:00"]
    }
  ]
}
```

- Seulement les traitements en cours ou à venir (pas ceux déjà terminés)
- `prescrit_par` : id du médecin, ou `null` si le patient l'a ajouté lui-même
- `heures` : heures de rappel, calculées automatiquement par le serveur

## 8. Ajouter un médicament (patient)

`POST /api/patients/me/traitements` — token obligatoire, rôle patient
Écran : `AddTraitementPage` (réutilisé côté patient)

```json
{
  "nom": "Plaquenil",
  "dosage": "200 mg",
  "fois_par_jour": 2,
  "debut": "2026-11-01",
  "fin": "2026-12-31"
}
```

- `nom` et `dosage` : obligatoires
- `fois_par_jour` : de 1 à 6
- `debut` : optionnel (aujourd'hui par défaut) ; `fin` : optionnel, pas avant `debut`
- Heures de rappel automatiques :

| `fois_par_jour` | Heures |
| --- | --- |
| 1 | 08:00 |
| 2 | 08:00, 20:00 |
| 3 | 08:00, 14:00, 20:00 |
| 4 | 08:00, 12:00, 16:00, 20:00 |
| 5 | 08:00, 11:00, 14:00, 17:00, 20:00 |
| 6 | 08:00, 10:00, 12:00, 14:00, 16:00, 18:00 |

Réponse **201** : `"message": "Médicament ajouté"` + `traitement` (même format qu'au §7)
Erreur : **400** (champ manquant, `fois_par_jour` invalide, date invalide ou fin avant début)

## 9. Prises du jour

`GET /api/patients/me/prises/aujourdhui` — token obligatoire, rôle patient
Écrans : « Rappels » (onglet Médicaments) et carte « Aujourd'hui » de l'accueil

```json
{
  "message": "Prises du jour",
  "date": "2026-11-24",
  "prises": [
    {
      "rappel_id": 4,
      "traitement_id": 2,
      "heure": "08:00",
      "nom": "Plaquenil",
      "dosage": "200 mg",
      "pris": true,
      "heure_prise": "08:12"
    },
    {
      "rappel_id": 5,
      "traitement_id": 2,
      "heure": "20:00",
      "nom": "Plaquenil",
      "dosage": "200 mg",
      "pris": false,
      "heure_prise": null
    }
  ]
}
```

- Triées par heure
- Accueil « Prochaine prise » : prendre la première prise avec `"pris": false`

## 10. Marquer une prise

`POST /api/patients/me/prises` — token obligatoire, rôle patient
Bouton « Marquer pris »

```json
{ "rappel_id": 5 }
```

- Envoyer deux fois ne crée pas de doublon (la 1re `heure_prise` est gardée)

Réponse **200** :

```json
{
  "message": "Prise enregistrée",
  "prise": { "rappel_id": 5, "traitement_id": 2, "heure": "20:00", "pris": true, "heure_prise": "20:03" }
}
```

Erreurs : **400** (`rappel_id` manquant), **404** (rappel introuvable ou traitement pas en cours aujourd'hui)

## 11. Traitements d'un patient (médecin)

Le médecin ne peut accéder qu'aux patients qu'il suit (table `suivi_medical`).

`GET /api/medecin/patients/:patientId/traitements` — token obligatoire, rôle médecin
Écran : fiche patient, onglet « Traitements »

Réponse **200** : même format qu'au §7.

`POST /api/medecin/patients/:patientId/traitements` — token obligatoire, rôle médecin
Écran : `AddTraitementPage`

Corps : identique au §8. Le traitement est enregistré avec `prescrit_par` = id du médecin.

Réponse **201** : `"message": "Médicament ajouté"` + `traitement`
Erreurs : **400** (`patientId` ou champ invalide), **404** (« Patient introuvable parmi vos patients »)

✅ Branché dans l'app en séance 6 (fiche patient, onglet Traitements + « Prescrire »).

---

**Rendez-vous et analyses (séance 4)** : c'est le **médecin** qui les crée ; le patient les **consulte** seulement (ils apparaissent automatiquement dans son agenda).
Date et heure sont renvoyées séparément : `"date": "AAAA-MM-JJ"`, `"heure": "HH:MM"`.

## 12. Rendez-vous du patient

`GET /api/patients/me/rendez-vous` — token obligatoire, rôle patient
Écrans : « Mon agenda », onglet Rendez-vous de « Rappels », ligne RDV de l'accueil

```json
{
  "message": "Rendez-vous à venir",
  "rendez_vous": [
    {
      "id": 1,
      "date": "2026-11-27",
      "heure": "10:30",
      "motif": "Consultation de suivi",
      "lieu": "Cabinet Dr",
      "statut": "planifie",
      "medecin_id": 3,
      "medecin_nom": "Dr Martin",
      "medecin_specialite": "Rhumatologue"
    }
  ]
}
```

- Seulement les rendez-vous **planifiés et pas encore passés**, du plus proche au plus lointain
- Accueil : prendre le premier de la liste

## 13. Analyses du patient

`GET /api/patients/me/analyses` — token obligatoire, rôle patient
Écrans : « Mon agenda », onglet Analyses de « Rappels »

```json
{
  "message": "Analyses à venir",
  "analyses": [
    {
      "id": 1,
      "type_analyse": "Bilan sanguin",
      "date": "2026-11-28",
      "heure": "08:00",
      "laboratoire": "Labo Central",
      "statut": "prevue"
    }
  ]
}
```

- Seulement les analyses **prévues et pas encore passées**

## 14. Patients du médecin

`GET /api/medecin/patients` — token obligatoire, rôle médecin
Écrans : « Patients », « Choisir un patient », liste du formulaire « Nouveau rendez-vous »

```json
{
  "message": "Liste des patients",
  "patients": [
    {
      "id": 1,
      "nom": "Sarah Benali",
      "date_naissance": "2000-05-15",
      "sexe": "femme",
      "groupe_sanguin": "AB+",
      "derniere_activite": "2026-11-26T09:12:00",
      "alerte_niveau": "eleve",
      "alerte_message": "Douleur signalée à 9/10 dans le suivi du jour.",
      "douleur_7_jours": [null, 5, 6, null, 7, 8, 6],
      "rdv_cette_semaine": true
    }
  ]
}
```

- Seulement les patients suivis (`suivi_medical`), du plus récemment actif au moins actif
- `alerte_niveau` : `faible`, `moyen`, `eleve` ou `null` (l'alerte non traitée la plus grave)
- `douleur_7_jours` : 7 valeurs, du plus ancien jour à aujourd'hui ; `null` = pas de suivi ce jour-là
- `rdv_cette_semaine` : un rendez-vous non annulé avec ce médecin, du lundi au dimanche

`GET /api/medecin/patients/:patientId` → `{ "message": "Patient", "patient": {...} }` (même format) ; **404** si ce n'est pas un patient du médecin

## 14 bis. Rechercher un patient à ajouter (consentement)

`GET /api/medecin/patients/recherche?identifiant=sarah@test.com` — token obligatoire, rôle médecin
Écran : « Ajouter un patient »

- `identifiant` = email exact **ou** numéro de téléphone (les espaces et tirets sont ignorés, 8 chiffres minimum)
- Confidentialité : tant que le patient n'a pas accepté, seuls `id` et `nom` sont renvoyés (le reste vaut `null`)
- `demande_en_attente` : une demande a déjà été envoyée, le patient n'a pas encore répondu

Réponse **200** :

```json
{
  "message": "Patient trouvé",
  "patient": { "id": 4, "nom": "Rania Ouali", "date_naissance": null, "sexe": null, "groupe_sanguin": null },
  "deja_suivi": false,
  "demande_en_attente": false
}
```

Erreurs : **400** (identifiant vide ou téléphone trop court), **404** (« Aucun patient trouvé avec cet identifiant »)

## 14 ter. Demander à suivre un patient (consentement)

`POST /api/medecin/patients` — token obligatoire, rôle médecin

```json
{ "patient_id": 4 }
```

- Envoie une **demande de suivi** (table `demandes_suivi`). Le médecin **ne voit rien** du patient tant que celui-ci n'a pas accepté (§32-33).
- À l'acceptation : `suivi_medical` + `acces_dossier` sont créés. Une demande refusée peut être renvoyée.

Réponse **201** : `"message": "Demande envoyée au patient"` + `demande` (`id`, `patient_id`, `statut`)
Erreurs : **400** (`patient_id` manquant), **404** (patient introuvable), **409** (« Ce patient est déjà dans votre liste » ou « Demande déjà envoyée, en attente de la réponse du patient »)

## 15. Agenda du médecin

`GET /api/medecin/rendez-vous` — token obligatoire, rôle médecin
Écran : `AgendaPage`

```json
{
  "message": "Agenda",
  "rendez_vous": [
    {
      "id": 1,
      "patient_id": 1,
      "patient_nom": "Sarah Benali",
      "date": "2026-11-27",
      "heure": "10:30",
      "motif": "Consultation de suivi",
      "lieu": "Cabinet Dr",
      "statut": "planifie"
    }
  ]
}
```

- Tous les rendez-vous du médecin (passés et à venir, tous statuts), triés par date

## 16. Nouveau rendez-vous (médecin)

`POST /api/medecin/rendez-vous` — token obligatoire, rôle médecin
Écran : `NewRdvPage`

```json
{
  "patient_id": 1,
  "date": "2026-12-02",
  "heure": "11:00",
  "lieu": "Cabinet",
  "motif": "Contrôle"
}
```

- `patient_id`, `date`, `heure`, `motif` : obligatoires ; `lieu` : optionnel
- Le patient doit être suivi par le médecin

Réponse **201** : `"message": "Rendez-vous ajouté"` + `rendez_vous` (même format qu'au §15)
Erreurs : **400** (champ manquant ou invalide), **404** (« Patient introuvable parmi vos patients »)

## 17. Terminer / annuler un rendez-vous (médecin)

`PUT /api/medecin/rendez-vous/:id/statut` — token obligatoire, rôle médecin
Écran : `AgendaPage` (menu « Marquer terminé » / « Annuler »)

```json
{ "statut": "termine" }
```

- `statut` : `termine` ou `annule`
- Seulement un rendez-vous du médecin encore `planifie`

Réponse **200** : `"message": "Rendez-vous terminé"` (ou `"Rendez-vous annulé"`) + `id`, `statut`
Erreurs : **400** (statut invalide, ou rendez-vous déjà terminé/annulé), **404** (rendez-vous introuvable)

## 18. Prescrire une analyse (médecin)

`POST /api/medecin/analyses` — token obligatoire, rôle médecin
Écran : **pas encore d'écran** (testé avec Postman)

```json
{
  "patient_id": 1,
  "type_analyse": "Bilan hépatique",
  "date": "2026-12-03",
  "heure": "08:00",
  "laboratoire": "Labo Central"
}
```

- `patient_id`, `type_analyse`, `date`, `heure` : obligatoires ; `laboratoire` : optionnel
- Le patient doit être suivi par le médecin

Réponse **201** : `"message": "Analyse ajoutée"` + `analyse`
Erreurs : **400** (champ manquant ou invalide), **404** (« Patient introuvable parmi vos patients »)

---

**Dossier médical (séance 5)** : c'est le **médecin** qui ajoute les documents ; le patient les **consulte**.
Pas encore de vrai fichier : seulement titre, type et date (`fichier_url` vaut `null`).
Un médecin qui suit un patient a automatiquement accès à son dossier (table `acces_dossier`).

Types de document : `ordonnance`, `analyse`, `compte_rendu`, `imagerie`, `autre`.

## 19. Documents du patient

`GET /api/patients/me/documents` — token obligatoire, rôle patient
Écran : « Dossier médical »

```json
{
  "message": "Documents du dossier",
  "documents": [
    {
      "id": 2,
      "titre": "Ordonnance Plaquenil",
      "type_document": "ordonnance",
      "date_document": "2026-11-02",
      "fichier_url": null
    }
  ]
}
```

- Du plus récent au plus ancien

## 20. Dossier partagé avec

`GET /api/patients/me/partages` — token obligatoire, rôle patient
Écran : « Dossier médical », section « Partagé avec »

```json
{
  "message": "Dossier partagé avec",
  "partages": [
    {
      "medecin_id": 3,
      "medecin_nom": "Karim Martin",
      "medecin_specialite": "Rhumatologue",
      "date_autorisation": "2026-11-26"
    }
  ]
}
```

## 21. Documents d'un patient (médecin)

`GET /api/medecin/patients/:patientId/documents` — token obligatoire, rôle médecin
Écran : fiche patient, onglet « Documents »

Réponse **200** : même format qu'au §19.
Erreur : **404** (« Dossier introuvable ou non partagé avec vous »)

## 22. Ajouter un document (médecin)

`POST /api/medecin/patients/:patientId/documents` — token obligatoire, rôle médecin
Écran : `AddDocumentPage` (fiche patient, action rapide « Compte rendu »)

```json
{
  "titre": "Radio des mains",
  "type_document": "imagerie",
  "date_document": "2026-11-25"
}
```

- `titre` et `type_document` : obligatoires ; `date_document` : optionnel (aujourd'hui par défaut)
- Le patient doit être suivi par le médecin

Réponse **201** : `"message": "Document ajouté"` + `document` (même format qu'au §19)
Erreurs : **400** (titre manquant, type ou date invalide), **404** (« Patient introuvable parmi vos patients »)

---

**Espace médecin (séance 6)**

## 23. Alertes du médecin

`GET /api/medecin/alertes` — token obligatoire, rôle médecin
Écran : « Alertes » (onglets « À traiter » / « Traitées »)

```json
{
  "message": "Alertes",
  "alertes": [
    {
      "id": 1,
      "patient_id": 1,
      "patient_nom": "Sarah Benali",
      "type": "douleur",
      "niveau": "eleve",
      "message": "Douleur signalée à 9/10 dans le suivi du jour.",
      "date": "2026-11-19T14:18:31",
      "traitee": false
    }
  ]
}
```

- Alertes des patients suivis, plus récentes d'abord. Créées automatiquement (douleur ≥ 8 dans le suivi du jour).
- `niveau` : `faible`, `moyen` ou `eleve`

## 24. Marquer une alerte traitée

`PUT /api/medecin/alertes/:id/traitee` — token obligatoire, rôle médecin (corps vide `{}`)

Réponse **200** : `"message": "Alerte traitée"` + `id`, `traitee`
Erreur : **404** (« Alerte introuvable », ou alerte d'un patient non suivi)

## 25. Accueil du médecin

`GET /api/medecin/accueil` — token obligatoire, rôle médecin
Écran : accueil du médecin (tableau de bord)

```json
{
  "message": "Accueil",
  "nom_medecin": "Karim Martin",
  "patients_suivis": 2,
  "alertes_aujourdhui": 0,
  "rendez_vous_a_venir": 2,
  "amelioration_moyenne": 12,
  "prochain_rdv": "2026-11-27",
  "patients_recents": [ { "id": 1, "nom": "Sarah Benali", "...": "même format qu'au §14" } ]
}
```

- `alertes_aujourdhui` : alertes encore à traiter
- `amelioration_moyenne` : baisse (en %) de la douleur moyenne des patients suivis, 7 derniers jours comparés aux 7 jours d'avant. Négatif si la douleur augmente, `0` s'il n'y a pas assez de données.
- `prochain_rdv` : jour du prochain RDV planifié (`null` s'il n'y en a pas) — bouton « RDV à venir » → ouvre l'agenda ce jour-là
- `patients_recents` : les 3 patients les plus récemment actifs

## 26. Profil du médecin

`GET /api/medecin/profil` — token obligatoire, rôle médecin

```json
{
  "message": "Profil",
  "profil": {
    "nom_complet": "Karim Martin",
    "email": "medecin@test.com",
    "telephone": "0567892312",
    "specialite": "Rhumatologue",
    "etablissement": null,
    "adresse": null,
    "ville": null
  }
}
```

## 27. Modifier le profil du médecin

`PUT /api/medecin/profil` — token obligatoire, rôle médecin

```json
{
  "nom_complet": "Karim Martin",
  "specialite": "Rhumatologue",
  "etablissement": "Clinique El Azhar",
  "adresse": "12 rue des Oliviers",
  "ville": "Alger",
  "telephone": "0567892312"
}
```

- `nom_complet` : obligatoire ; les autres champs sont optionnels (vide = effacé)
- L'email ne change pas. La photo de profil reste sur le téléphone (pas encore envoyée au serveur).

Réponse **200** : `"message": "Profil mis à jour"` + `profil`
Erreurs : **400** (nom manquant), **409** (« Ce numéro de téléphone est déjà utilisé »)

---

**Messagerie (séance 7)** : uniquement entre un médecin et un patient qu'il suit (`suivi_medical`).
Pas de temps réel : l'app recharge la discussion ouverte **toutes les 5 secondes**.
Format d'un message : `{ "id", "de_moi", "texte", "date": "AAAA-MM-JJTHH:MM:SS", "lu" }` (`de_moi` = envoyé par la personne connectée).

## 28. Mes médecins (patient)

`GET /api/patients/me/medecins` — token obligatoire, rôle patient
Écran : « Messages » du patient (icône 💬 de l'accueil)

```json
{
  "message": "Mes médecins",
  "medecins": [
    {
      "medecin_id": 3,
      "medecin_nom": "Karim Martin",
      "medecin_specialite": "Rhumatologue",
      "non_lus": 1,
      "dernier_message": { "id": 7, "de_moi": false, "texte": "Bonjour Sarah…", "date": "2026-11-26T15:02:11", "lu": false }
    }
  ]
}
```

- `dernier_message` vaut `null` s'il n'y a pas encore de message
- Point rouge de l'accueil patient = somme des `non_lus`

## 29. Discussion avec un médecin (patient)

`GET /api/patients/me/messages/:medecinId` → `{ "message": "Discussion", "messages": [...] }` (du plus ancien au plus récent ; les messages du médecin passent en « lu »)

`POST /api/patients/me/messages/:medecinId` avec `{ "texte": "Bonjour docteur" }` → **201** `"Message envoyé"` + `envoye`

Erreurs : **400** (« Le message est vide », trop long > 2000 caractères), **403** (« Vous ne pouvez écrire qu'à un médecin qui vous suit »)

## 30. Conversations (médecin)

`GET /api/medecin/conversations` — token obligatoire, rôle médecin
Écran : « Messages » du médecin

```json
{
  "message": "Conversations",
  "conversations": [
    {
      "patient": { "id": 1, "nom": "Sarah Benali", "...": "même format qu'au §14" },
      "dernier_message": { "id": 6, "de_moi": false, "texte": "Bonjour docteur…", "date": "2026-11-26T14:58:40", "lu": false },
      "non_lus": 1
    }
  ]
}
```

- Patients suivis avec au moins un message, discussion la plus récente d'abord
- Point rouge de l'accueil médecin : `messages_non_lus` dans `GET /api/medecin/accueil` (§25)

## 31. Discussion avec un patient (médecin)

`GET /api/medecin/messages/:patientId` → messages (les messages du patient passent en « lu »)

`POST /api/medecin/messages/:patientId` avec `{ "texte": "..." }` → **201** `"Message envoyé"`

Erreurs : **400** (message vide ou trop long), **404** (« Patient introuvable parmi vos patients »)

---

**Consentement du patient (sécurité)** : un médecin ne voit le dossier d'un patient qu'après que le patient a **accepté** sa demande.

## 32. Demandes de suivi (patient)

`GET /api/patients/me/demandes` — token obligatoire, rôle patient
Écran : bandeau « Dr … souhaite vous suivre » sur l'accueil patient

```json
{
  "message": "Demandes de suivi",
  "demandes": [
    {
      "id": 1,
      "medecin_id": 3,
      "medecin_nom": "Karim Martin",
      "medecin_specialite": "Rhumatologue",
      "medecin_etablissement": null,
      "date": "2026-11-26T16:20:00"
    }
  ]
}
```

- Seulement les demandes **en attente**

## 33. Accepter / refuser une demande (patient)

`PUT /api/patients/me/demandes/:id` — token obligatoire, rôle patient

```json
{ "decision": "accepter" }
```

- `decision` : `accepter` ou `refuser`
- Accepter : le médecin suit le patient et a accès à son dossier ; il peut aussi lui écrire

Réponse **200** : `"message": "Demande acceptée : ce médecin vous suit maintenant"` (ou `"Demande refusée"`) + `id`, `statut`
Erreurs : **400** (décision invalide), **404** (« Demande introuvable ou déjà traitée »)

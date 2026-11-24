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
- Mot de passe : 6 caractères minimum
- L'écran « Créer un compte » et l'écran « Type de compte » sont séparés : garder les infos du 1er écran et appeler `register` après le choix du rôle.

Réponse **201** : `message`, `token`, `user`
Erreurs : **400** (champ manquant), **409** (email ou téléphone déjà utilisé)

## 2. Connexion

`POST /api/auth/login` — pas de token

```json
{
  "identifiant": "sarah@test.com",
  "mot_de_passe": "123456"
}
```

- `identifiant` = email **ou** numéro de téléphone

Réponse **200** : `message`, `token`, `user`
Erreur : **401** (identifiant ou mot de passe incorrect)

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

⚠️ À brancher dans l'app en séance 6, quand la liste des patients du médecin viendra du backend (les ids actuels de `medecin_service.dart` sont fictifs).

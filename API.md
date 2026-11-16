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

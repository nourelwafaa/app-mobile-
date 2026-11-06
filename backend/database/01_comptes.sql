-- =========================================
-- Creative Lupus+ : Partie 1 — Comptes
-- =========================================

-- 1. Tous les utilisateurs (inscription / connexion)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    nom_complet VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telephone VARCHAR(20) UNIQUE,
    mot_de_passe VARCHAR(255),
    date_naissance DATE,
    role VARCHAR(30) NOT NULL
        CHECK (role IN ('patient', 'proche', 'medecin', 'pharmacien', 'etudiant_medecine', 'autre')),
    auth_provider VARCHAR(20) NOT NULL DEFAULT 'local'
        CHECK (auth_provider IN ('local', 'google', 'facebook')),
    photo VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- un compte classique doit avoir un mot de passe
    CHECK (auth_provider <> 'local' OR mot_de_passe IS NOT NULL)
);

-- 2. Informations du patient (écran "Ajouter des informations")
CREATE TABLE patients (
    user_id INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    sexe VARCHAR(10) CHECK (sexe IN ('homme', 'femme')),
    poids NUMERIC(5,2) CHECK (poids > 0),
    taille NUMERIC(5,2) CHECK (taille > 0),
    groupe_sanguin VARCHAR(3)
        CHECK (groupe_sanguin IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))
);

-- 3. Professionnels de santé (médecin, pharmacien, étudiant en médecine)
CREATE TABLE professionnels (
    user_id INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    specialite VARCHAR(100),
    etablissement VARCHAR(150),
    adresse VARCHAR(255),
    ville VARCHAR(100),
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6)
);

-- 4. Lien proche <-> patient
CREATE TABLE proches_patients (
    id SERIAL PRIMARY KEY,
    proche_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    lien VARCHAR(50),
    UNIQUE (proche_id, patient_id)
);

-- 5. Médecin qui suit un patient (et accès autorisé à son dossier)
CREATE TABLE suivi_medical (
    id SERIAL PRIMARY KEY,
    medecin_id INT NOT NULL REFERENCES professionnels(user_id) ON DELETE CASCADE,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    date_debut DATE DEFAULT CURRENT_DATE,
    UNIQUE (medecin_id, patient_id)
);
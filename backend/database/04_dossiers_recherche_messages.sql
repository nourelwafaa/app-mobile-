-- =========================================
-- Creative Lupus+ : Partie 4 — Dossier médical, recherche, messagerie, communauté
-- =========================================

-- 1. Documents médicaux du patient
CREATE TABLE documents_medicaux (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    titre VARCHAR(150) NOT NULL,
    type_document VARCHAR(30) NOT NULL DEFAULT 'autre'
        CHECK (type_document IN ('ordonnance', 'analyse', 'compte_rendu', 'imagerie', 'autre')),
    fichier_url VARCHAR(255) NOT NULL,
    date_document DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Partage sécurisé : quel professionnel (médecin, pharmacien) peut voir le dossier
CREATE TABLE acces_dossier (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    professionnel_id INT NOT NULL REFERENCES professionnels(user_id) ON DELETE CASCADE,
    date_autorisation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (patient_id, professionnel_id)
);

-- 3. Établissements de santé (recherche + carte)
CREATE TABLE etablissements (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(150) NOT NULL,
    type VARCHAR(20) NOT NULL
        CHECK (type IN ('pharmacie', 'clinique', 'laboratoire')),
    adresse VARCHAR(255),
    ville VARCHAR(100),
    telephone VARCHAR(20),
    horaires VARCHAR(150),
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6)
);

-- 4. Messagerie privée
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    expediteur_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    destinataire_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contenu TEXT NOT NULL,
    lu BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (expediteur_id <> destinataire_id)
);

-- 5. Communauté : publications
CREATE TABLE publications (
    id SERIAL PRIMARY KEY,
    auteur_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contenu TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Communauté : commentaires
CREATE TABLE commentaires (
    id SERIAL PRIMARY KEY,
    publication_id INT NOT NULL REFERENCES publications(id) ON DELETE CASCADE,
    auteur_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contenu TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
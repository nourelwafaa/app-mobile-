-- =========================================
-- Creative Lupus+ : Partie 2 — Suivi du patient
-- =========================================

-- 1. Suivi du jour (une fiche par patient et par jour)
CREATE TABLE suivi_quotidien (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    date_suivi DATE NOT NULL DEFAULT CURRENT_DATE,
    douleur INT CHECK (douleur BETWEEN 0 AND 10),
    fatigue INT CHECK (fatigue BETWEEN 0 AND 10),
    humeur INT CHECK (humeur BETWEEN 0 AND 10),
    sommeil_heures NUMERIC(3,1) CHECK (sommeil_heures BETWEEN 0 AND 24),
    remarque TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (patient_id, date_suivi)
);

-- 2. Symptômes enregistrés
CREATE TABLE symptomes (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    nom VARCHAR(100) NOT NULL,
    intensite INT CHECK (intensite BETWEEN 1 AND 10),
    date_symptome TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarque TEXT
);

-- 3. Journal de santé
CREATE TABLE journal_sante (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    titre VARCHAR(150),
    contenu TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Alertes (état du patient, visibles par le médecin)
CREATE TABLE alertes (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    niveau VARCHAR(10) NOT NULL DEFAULT 'moyen'
        CHECK (niveau IN ('faible', 'moyen', 'eleve')),
    traitee BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
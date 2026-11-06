-- =========================================
-- Creative Lupus+ : Partie 3 — Médicaments, rendez-vous, analyses
-- =========================================

-- 1. Traitements / médicaments du patient
CREATE TABLE traitements (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    prescrit_par INT REFERENCES professionnels(user_id) ON DELETE SET NULL,
    nom_medicament VARCHAR(150) NOT NULL,
    dosage VARCHAR(50),
    frequence VARCHAR(100),
    date_debut DATE NOT NULL DEFAULT CURRENT_DATE,
    date_fin DATE,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (date_fin IS NULL OR date_fin >= date_debut)
);

-- 2. Heures de rappel pour chaque médicament
CREATE TABLE rappels_medicament (
    id SERIAL PRIMARY KEY,
    traitement_id INT NOT NULL REFERENCES traitements(id) ON DELETE CASCADE,
    heure TIME NOT NULL,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (traitement_id, heure)
);

-- 3. Suivi des prises (pris / oublié)
CREATE TABLE prises_medicament (
    id SERIAL PRIMARY KEY,
    traitement_id INT NOT NULL REFERENCES traitements(id) ON DELETE CASCADE,
    date_prevue TIMESTAMP NOT NULL,
    statut VARCHAR(15) NOT NULL DEFAULT 'en_attente'
        CHECK (statut IN ('en_attente', 'prise', 'oubliee')),
    heure_prise TIMESTAMP
);

-- 4. Rendez-vous médicaux (présentiel ou vidéo Jitsi)
CREATE TABLE rendez_vous (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    medecin_id INT REFERENCES professionnels(user_id) ON DELETE SET NULL,
    date_heure TIMESTAMP NOT NULL,
    type VARCHAR(15) NOT NULL DEFAULT 'presentiel'
        CHECK (type IN ('presentiel', 'video')),
    lien_video VARCHAR(255),
    lieu VARCHAR(255),
    motif TEXT,
    statut VARCHAR(15) NOT NULL DEFAULT 'planifie'
        CHECK (statut IN ('planifie', 'termine', 'annule')),
    rappel_minutes INT DEFAULT 60,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- un RDV vidéo doit avoir son lien
    CHECK (type <> 'video' OR lien_video IS NOT NULL)
);

-- 5. Analyses de laboratoire
CREATE TABLE analyses (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    type_analyse VARCHAR(150) NOT NULL,
    date_prevue TIMESTAMP NOT NULL,
    laboratoire VARCHAR(150),
    statut VARCHAR(15) NOT NULL DEFAULT 'prevue'
        CHECK (statut IN ('prevue', 'faite', 'annulee')),
    resultat TEXT,
    rappel_minutes INT DEFAULT 1440,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
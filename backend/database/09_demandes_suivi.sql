-- =========================================
-- Creative Lupus+ : Partie 9 — Consentement du patient
-- =========================================
-- À exécuter une fois dans pgAdmin (base creative_lupus), après les fichiers 01 à 08.
-- Le script peut être relancé sans erreur.

-- Un médecin ne suit plus un patient directement : il lui envoie une DEMANDE.
-- Le patient l'accepte (→ suivi_medical + acces_dossier sont créés) ou la refuse.
CREATE TABLE IF NOT EXISTS demandes_suivi (
    id SERIAL PRIMARY KEY,
    medecin_id INT NOT NULL REFERENCES professionnels(user_id) ON DELETE CASCADE,
    patient_id INT NOT NULL REFERENCES patients(user_id) ON DELETE CASCADE,
    statut VARCHAR(15) NOT NULL DEFAULT 'en_attente'
        CHECK (statut IN ('en_attente', 'acceptee', 'refusee')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_reponse TIMESTAMP,
    UNIQUE (medecin_id, patient_id)
);

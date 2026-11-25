-- =========================================
-- Creative Lupus+ : Partie 6 — Séance 3 : une seule prise par médicament et par horaire
-- =========================================
-- À exécuter une fois dans pgAdmin (base creative_lupus), après les fichiers 01 à 05.
-- Le script peut être relancé sans erreur.

-- 1. Supprimer d'éventuels doublons (on garde la ligne la plus ancienne)
DELETE FROM prises_medicament a
USING prises_medicament b
WHERE a.traitement_id = b.traitement_id
  AND a.date_prevue = b.date_prevue
  AND a.id > b.id;

-- 2. Un médicament ne peut avoir qu'une prise pour une même date + heure prévue
--    (ex. traitement 1, le 2026-11-24 à 08:00 → une seule ligne)
ALTER TABLE prises_medicament
    DROP CONSTRAINT IF EXISTS prises_unique_traitement_date;

ALTER TABLE prises_medicament
    ADD CONSTRAINT prises_unique_traitement_date UNIQUE (traitement_id, date_prevue);

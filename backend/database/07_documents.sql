-- =========================================
-- Creative Lupus+ : Partie 7 — Séance 5 : dossier médical
-- =========================================
-- À exécuter une fois dans pgAdmin (base creative_lupus), après les fichiers 01 à 06.
-- Le script peut être relancé sans erreur.

-- 1. Pas encore d'envoi de fichier dans l'app : on enregistre seulement
--    titre, type et date. Le fichier devient donc facultatif.
ALTER TABLE documents_medicaux
    ALTER COLUMN fichier_url DROP NOT NULL;

-- 2. Partage automatique : chaque médecin qui suit un patient a accès à son dossier.
--    (Pour les patients déjà suivis, ex. Sarah. Les prochains suivis créeront
--     l'accès eux-mêmes, séance 6.)
INSERT INTO acces_dossier (patient_id, professionnel_id)
SELECT patient_id, medecin_id
FROM suivi_medical
ON CONFLICT (patient_id, professionnel_id) DO NOTHING;

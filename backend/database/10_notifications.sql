-- =========================================
-- Creative Lupus+ : Partie 10 — Notifications du médecin
-- =========================================
-- À exécuter une fois dans pgAdmin (base creative_lupus), après les fichiers 01 à 09.
-- Le script peut être relancé sans erreur.

-- Chaque notification garde :
--   patient_id : le patient concerné (pour ouvrir sa discussion)
--   ref_id     : l'id de ce qui l'a créée (message, alerte ou rendez-vous), pour ne pas la créer 2 fois
--   date_cible : pour un rendez-vous, sa date (pour ouvrir l'Agenda sur ce jour)
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS patient_id INT REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS ref_id INT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS date_cible TIMESTAMP;

-- Une seule notification par (médecin, type, message/alerte/rendez-vous)
CREATE UNIQUE INDEX IF NOT EXISTS notifications_unique
    ON notifications (user_id, type, ref_id);

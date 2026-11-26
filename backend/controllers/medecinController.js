const db = require("../config/db");

// Espace médecin (séance 6) : ses patients, la recherche et l'ajout d'un patient.

// Un patient suivi, avec tout ce qu'affichent la liste et la fiche :
// - alerte en cours : la plus grave non traitée (puis la plus récente)
// - douleur des 7 derniers jours (du plus ancien à aujourd'hui, null = pas de suivi ce jour-là)
// - rdv_cette_semaine : un RDV non annulé avec ce médecin, du lundi au dimanche
const SELECT_PATIENT_SUIVI = `
    SELECT u.id,
           u.nom_complet AS nom,
           u.date_naissance,
           p.sexe,
           p.groupe_sanguin,
           to_char(
               COALESCE((SELECT MAX(s.created_at) FROM suivi_quotidien s WHERE s.patient_id = u.id),
                        sm.date_debut::timestamp),
               'YYYY-MM-DD"T"HH24:MI:SS'
           ) AS derniere_activite,
           a.niveau AS alerte_niveau,
           a.message AS alerte_message,
           ARRAY(
               SELECT s.douleur
               FROM generate_series(CURRENT_DATE - 6, CURRENT_DATE, INTERVAL '1 day') AS j
               LEFT JOIN suivi_quotidien s ON s.patient_id = u.id AND s.date_suivi = j::date
               ORDER BY j
           ) AS douleur_7_jours,
           EXISTS (
               SELECT 1 FROM rendez_vous r
               WHERE r.patient_id = u.id
                 AND r.medecin_id = sm.medecin_id
                 AND r.statut <> 'annule'
                 AND r.date_heure >= date_trunc('week', CURRENT_DATE)
                 AND r.date_heure <  date_trunc('week', CURRENT_DATE) + INTERVAL '7 days'
           ) AS rdv_cette_semaine
    FROM suivi_medical sm
    JOIN users u ON u.id = sm.patient_id
    JOIN patients p ON p.user_id = u.id
    LEFT JOIN LATERAL (
        SELECT al.niveau, al.message
        FROM alertes al
        WHERE al.patient_id = u.id AND al.traitee = FALSE
        ORDER BY CASE al.niveau WHEN 'eleve' THEN 3 WHEN 'moyen' THEN 2 ELSE 1 END DESC,
                 al.created_at DESC
        LIMIT 1
    ) a ON TRUE
    WHERE sm.medecin_id = $1`;

// GET /api/medecin/patients : écran « Patients » (+ choix d'un patient, nouveau RDV)
exports.mesPatients = async (req, res) => {
    try {
        const result = await db.query(
            `${SELECT_PATIENT_SUIVI} ORDER BY derniere_activite DESC, u.nom_complet`,
            [req.user.id]
        );
        res.json({ message: "Liste des patients", patients: result.rows });
    } catch (error) {
        console.error("Erreur patients médecin :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// GET /api/medecin/patients/:patientId : un patient suivi (ex. ouvrir la fiche depuis une alerte)
exports.unPatient = async (req, res) => {
    const patientId = Number(req.params.patientId);
    if (!Number.isInteger(patientId) || patientId <= 0) {
        return res.status(400).json({ message: "Identifiant de patient invalide" });
    }
    try {
        const result = await db.query(`${SELECT_PATIENT_SUIVI} AND u.id = $2`, [req.user.id, patientId]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Patient introuvable parmi vos patients" });
        }
        res.json({ message: "Patient", patient: result.rows[0] });
    } catch (error) {
        console.error("Erreur patient :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// GET /api/medecin/patients/recherche?identifiant=... : écran « Ajouter un patient »
// Cherche un patient inscrit par email exact ou par numéro de téléphone (au moins 8 chiffres).
exports.rechercherPatient = async (req, res) => {
    const saisie = String(req.query.identifiant || "").trim().toLowerCase();
    if (!saisie) {
        return res.status(400).json({ message: "Saisissez un email ou un numéro de téléphone" });
    }
    const estEmail = saisie.includes("@");
    const chiffres = saisie.replace(/\D/g, "");
    if (!estEmail && chiffres.length < 8) {
        return res.status(400).json({ message: "Numéro de téléphone invalide" });
    }

    try {
        const result = await db.query(
            `SELECT u.id,
                    u.nom_complet AS nom,
                    u.date_naissance,
                    p.sexe,
                    p.groupe_sanguin,
                    EXISTS (
                        SELECT 1 FROM suivi_medical sm
                        WHERE sm.medecin_id = $3 AND sm.patient_id = u.id
                    ) AS deja_suivi
             FROM users u
             JOIN patients p ON p.user_id = u.id
             WHERE u.role = 'patient'
               AND (($1::boolean AND LOWER(u.email) = $2)
                 OR (NOT $1::boolean AND regexp_replace(COALESCE(u.telephone, ''), '\\D', '', 'g') = $4))
             LIMIT 1`,
            [estEmail, saisie, req.user.id, chiffres]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Aucun patient trouvé avec cet identifiant" });
        }
        const { deja_suivi, ...patient } = result.rows[0];
        res.json({ message: "Patient trouvé", patient, deja_suivi });
    } catch (error) {
        console.error("Erreur recherche patient :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// POST /api/medecin/patients : le médecin commence à suivre un patient
// Corps : { patient_id }. Crée aussi l'accès au dossier médical (acces_dossier).
exports.ajouterPatient = async (req, res) => {
    const patientId = Number(req.body?.patient_id);
    if (!Number.isInteger(patientId) || patientId <= 0) {
        return res.status(400).json({ message: "patient_id est obligatoire" });
    }

    const client = await db.connect();
    try {
        const patient = await client.query("SELECT 1 FROM patients WHERE user_id = $1", [patientId]);
        if (patient.rows.length === 0) {
            return res.status(404).json({ message: "Patient introuvable" });
        }

        await client.query("BEGIN");
        const suivi = await client.query(
            `INSERT INTO suivi_medical (medecin_id, patient_id) VALUES ($1, $2)
             ON CONFLICT (medecin_id, patient_id) DO NOTHING
             RETURNING id`,
            [req.user.id, patientId]
        );
        if (suivi.rows.length === 0) {
            await client.query("ROLLBACK");
            return res.status(409).json({ message: "Ce patient est déjà dans votre liste" });
        }
        await client.query(
            `INSERT INTO acces_dossier (patient_id, professionnel_id) VALUES ($1, $2)
             ON CONFLICT (patient_id, professionnel_id) DO NOTHING`,
            [patientId, req.user.id]
        );
        await client.query("COMMIT");

        const result = await db.query(`${SELECT_PATIENT_SUIVI} AND u.id = $2`, [req.user.id, patientId]);
        res.status(201).json({ message: "Patient ajouté", patient: result.rows[0] });
    } catch (error) {
        await client.query("ROLLBACK").catch(() => {});
        console.error("Erreur ajout patient :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    } finally {
        client.release();
    }
};

// ---------- Alertes (séance 6b) ----------

// GET /api/medecin/alertes : alertes des patients suivis (à traiter + traitées), plus récentes d'abord
// Les alertes sont créées automatiquement (ex. douleur ≥ 8 dans le suivi du jour, séance 2).
exports.mesAlertes = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT a.id,
                    a.patient_id,
                    u.nom_complet AS patient_nom,
                    a.type,
                    a.niveau,
                    a.message,
                    to_char(a.created_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS date,
                    a.traitee
             FROM alertes a
             JOIN suivi_medical sm ON sm.patient_id = a.patient_id AND sm.medecin_id = $1
             JOIN users u ON u.id = a.patient_id
             ORDER BY a.created_at DESC, a.id DESC`,
            [req.user.id]
        );
        res.json({ message: "Alertes", alertes: result.rows });
    } catch (error) {
        console.error("Erreur alertes :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// PUT /api/medecin/alertes/:id/traitee : bouton « Marquer comme traitée »
exports.traiterAlerte = async (req, res) => {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({ message: "Identifiant d'alerte invalide" });
    }
    try {
        // Seulement une alerte d'un patient suivi par ce médecin
        const result = await db.query(
            `UPDATE alertes a SET traitee = TRUE
             FROM suivi_medical sm
             WHERE a.id = $1 AND sm.patient_id = a.patient_id AND sm.medecin_id = $2
             RETURNING a.id, a.traitee`,
            [id, req.user.id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Alerte introuvable" });
        }
        res.json({ message: "Alerte traitée", id, traitee: true });
    } catch (error) {
        console.error("Erreur traiter alerte :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// ---------- Accueil (séance 6c) ----------

// GET /api/medecin/accueil : tableau de bord du médecin
// - alertes_aujourdhui : alertes encore à traiter
// - amelioration_moyenne : baisse de la douleur moyenne des patients suivis,
//   7 derniers jours comparés aux 7 jours d'avant (en %, négatif si la douleur augmente ;
//   0 s'il n'y a pas assez de données)
exports.accueil = async (req, res) => {
    const medecinId = req.user.id;
    try {
        const compteurs = await db.query(
            `SELECT
                (SELECT nom_complet FROM users WHERE id = $1) AS nom_medecin,
                (SELECT COUNT(*)::int FROM suivi_medical WHERE medecin_id = $1) AS patients_suivis,
                (SELECT COUNT(*)::int
                   FROM alertes a JOIN suivi_medical sm ON sm.patient_id = a.patient_id AND sm.medecin_id = $1
                  WHERE a.traitee = FALSE) AS alertes_aujourdhui,
                (SELECT COUNT(*)::int FROM rendez_vous
                  WHERE medecin_id = $1 AND statut = 'planifie' AND date_heure >= CURRENT_TIMESTAMP) AS rendez_vous_a_venir,
                (SELECT to_char(MIN(date_heure), 'YYYY-MM-DD') FROM rendez_vous
                  WHERE medecin_id = $1 AND statut = 'planifie' AND date_heure >= CURRENT_TIMESTAMP) AS prochain_rdv,
                (SELECT AVG(s.douleur)::float
                   FROM suivi_quotidien s JOIN suivi_medical sm ON sm.patient_id = s.patient_id AND sm.medecin_id = $1
                  WHERE s.date_suivi > CURRENT_DATE - 7) AS douleur_actuelle,
                (SELECT AVG(s.douleur)::float
                   FROM suivi_quotidien s JOIN suivi_medical sm ON sm.patient_id = s.patient_id AND sm.medecin_id = $1
                  WHERE s.date_suivi <= CURRENT_DATE - 7 AND s.date_suivi > CURRENT_DATE - 14) AS douleur_precedente`,
            [medecinId]
        );
        const c = compteurs.rows[0];

        let amelioration = 0;
        if (c.douleur_actuelle !== null && c.douleur_precedente) {
            amelioration = Math.round(((c.douleur_precedente - c.douleur_actuelle) / c.douleur_precedente) * 100);
        }

        // Les 3 patients les plus récemment actifs (même format que GET /patients)
        const recents = await db.query(
            `${SELECT_PATIENT_SUIVI} ORDER BY derniere_activite DESC, u.nom_complet LIMIT 3`,
            [medecinId]
        );

        res.json({
            message: "Accueil",
            nom_medecin: c.nom_medecin,
            patients_suivis: c.patients_suivis,
            alertes_aujourdhui: c.alertes_aujourdhui,
            rendez_vous_a_venir: c.rendez_vous_a_venir,
            amelioration_moyenne: amelioration,
            prochain_rdv: c.prochain_rdv,
            patients_recents: recents.rows
        });
    } catch (error) {
        console.error("Erreur accueil médecin :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// ---------- Profil (séance 6c) ----------

const SELECT_PROFIL = `
    SELECT u.nom_complet, u.email, u.telephone,
           p.specialite, p.etablissement, p.adresse, p.ville
    FROM users u
    JOIN professionnels p ON p.user_id = u.id
    WHERE u.id = $1`;

// GET /api/medecin/profil : page « Profil »
exports.monProfil = async (req, res) => {
    try {
        const result = await db.query(SELECT_PROFIL, [req.user.id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Profil introuvable" });
        }
        res.json({ message: "Profil", profil: result.rows[0] });
    } catch (error) {
        console.error("Erreur profil médecin :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// PUT /api/medecin/profil : page « Modifier le profil » (l'email ne change pas)
// Corps : { nom_complet, specialite?, etablissement?, adresse?, ville?, telephone? }
exports.majProfil = async (req, res) => {
    const b = req.body || {};
    const texte = (v, max) => {
        if (v === undefined || v === null) return null;
        const t = String(v).trim();
        return t ? t.slice(0, max) : null;
    };

    const nom = texte(b.nom_complet, 150);
    if (!nom) return res.status(400).json({ message: "Le nom est obligatoire" });
    const telephone = texte(b.telephone, 20);

    const client = await db.connect();
    try {
        await client.query("BEGIN");
        await client.query(
            "UPDATE users SET nom_complet = $1, telephone = $2 WHERE id = $3",
            [nom, telephone, req.user.id]
        );
        await client.query(
            `UPDATE professionnels
             SET specialite = $1, etablissement = $2, adresse = $3, ville = $4
             WHERE user_id = $5`,
            [texte(b.specialite, 100), texte(b.etablissement, 150), texte(b.adresse, 255), texte(b.ville, 100), req.user.id]
        );
        await client.query("COMMIT");

        const result = await db.query(SELECT_PROFIL, [req.user.id]);
        res.json({ message: "Profil mis à jour", profil: result.rows[0] });
    } catch (error) {
        await client.query("ROLLBACK").catch(() => {});
        if (error.code === "23505") {
            return res.status(409).json({ message: "Ce numéro de téléphone est déjà utilisé" });
        }
        console.error("Erreur mise à jour profil :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    } finally {
        client.release();
    }
};

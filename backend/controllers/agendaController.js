const db = require("../config/db");

// Le médecin crée les rendez-vous et les analyses ; le patient les consulte.

// ---------- Routes patient ----------

// GET /api/patients/me/rendez-vous : rendez-vous à venir (planifiés), du plus proche au plus lointain
// Écrans : « Mon agenda », onglet Rendez-vous de « Rappels », ligne RDV de l'accueil
exports.mesRendezVous = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT r.id,
                    to_char(r.date_heure, 'YYYY-MM-DD') AS date,
                    to_char(r.date_heure, 'HH24:MI') AS heure,
                    r.motif,
                    r.lieu,
                    r.statut,
                    r.medecin_id,
                    u.nom_complet AS medecin_nom,
                    p.specialite AS medecin_specialite
             FROM rendez_vous r
             LEFT JOIN users u ON u.id = r.medecin_id
             LEFT JOIN professionnels p ON p.user_id = r.medecin_id
             WHERE r.patient_id = $1
               AND r.statut = 'planifie'
               AND r.date_heure >= CURRENT_TIMESTAMP
             ORDER BY r.date_heure`,
            [req.user.id]
        );
        res.json({ message: "Rendez-vous à venir", rendez_vous: result.rows });
    } catch (error) {
        console.error("Erreur rendez-vous patient :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// GET /api/patients/me/analyses : analyses à venir (prévues), de la plus proche à la plus lointaine
// Écrans : « Mon agenda », onglet Analyses de « Rappels »
exports.mesAnalyses = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT id,
                    type_analyse,
                    to_char(date_prevue, 'YYYY-MM-DD') AS date,
                    to_char(date_prevue, 'HH24:MI') AS heure,
                    laboratoire,
                    statut
             FROM analyses
             WHERE patient_id = $1
               AND statut = 'prevue'
               AND date_prevue >= CURRENT_TIMESTAMP
             ORDER BY date_prevue`,
            [req.user.id]
        );
        res.json({ message: "Analyses à venir", analyses: result.rows });
    } catch (error) {
        console.error("Erreur analyses patient :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// ---------- Routes médecin ----------

// Vérifie qu'une date est au format "AAAA-MM-JJ" et existe (pas de 2026-02-31)
function dateValide(v) {
    if (typeof v !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(v)) return false;
    const d = new Date(`${v}T00:00:00Z`);
    return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === v;
}

// Vérifie une heure "HH:MM" (00:00 à 23:59)
function heureValide(v) {
    return typeof v === "string" && /^([01]\d|2[0-3]):[0-5]\d$/.test(v);
}

// Le médecin suit-il ce patient ? (table suivi_medical)
async function suitLePatient(medecinId, patientId) {
    const r = await db.query(
        "SELECT 1 FROM suivi_medical WHERE medecin_id = $1 AND patient_id = $2",
        [medecinId, patientId]
    );
    return r.rows.length > 0;
}

// GET /api/medecin/patients : patients suivis par le médecin
// Version simple pour le formulaire « Nouveau rendez-vous » (complétée en séance 6)
exports.mesPatients = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT u.id,
                    u.nom_complet AS nom,
                    u.date_naissance,
                    p.sexe,
                    p.groupe_sanguin,
                    to_char(
                        COALESCE((SELECT MAX(s.created_at) FROM suivi_quotidien s WHERE s.patient_id = u.id),
                                 sm.date_debut::timestamp),
                        'YYYY-MM-DD"T"HH24:MI:SS'
                    ) AS derniere_activite
             FROM suivi_medical sm
             JOIN users u ON u.id = sm.patient_id
             JOIN patients p ON p.user_id = u.id
             WHERE sm.medecin_id = $1
             ORDER BY u.nom_complet`,
            [req.user.id]
        );
        res.json({ message: "Liste des patients", patients: result.rows });
    } catch (error) {
        console.error("Erreur patients médecin :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// GET /api/medecin/rendez-vous : agenda du médecin (tous ses rendez-vous, tous statuts)
exports.agendaMedecin = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT r.id,
                    r.patient_id,
                    u.nom_complet AS patient_nom,
                    to_char(r.date_heure, 'YYYY-MM-DD') AS date,
                    to_char(r.date_heure, 'HH24:MI') AS heure,
                    r.motif,
                    r.lieu,
                    r.statut
             FROM rendez_vous r
             JOIN users u ON u.id = r.patient_id
             WHERE r.medecin_id = $1
             ORDER BY r.date_heure`,
            [req.user.id]
        );
        res.json({ message: "Agenda", rendez_vous: result.rows });
    } catch (error) {
        console.error("Erreur agenda médecin :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// POST /api/medecin/rendez-vous : écran « Nouveau rendez-vous »
// Corps : { patient_id, date: "AAAA-MM-JJ", heure: "HH:MM", lieu?, motif }
exports.creerRendezVous = async (req, res) => {
    const { patient_id, date, heure, lieu, motif } = req.body || {};

    const patientId = Number(patient_id);
    if (!Number.isInteger(patientId) || patientId <= 0) {
        return res.status(400).json({ message: "Le patient est obligatoire" });
    }
    if (!dateValide(date)) return res.status(400).json({ message: "Date invalide (format AAAA-MM-JJ)" });
    if (!heureValide(heure)) return res.status(400).json({ message: "Heure invalide (format HH:MM)" });

    const m = typeof motif === "string" ? motif.trim() : "";
    if (!m) return res.status(400).json({ message: "Le motif est obligatoire" });
    const l = typeof lieu === "string" && lieu.trim() ? lieu.trim() : null;
    if (l && l.length > 255) return res.status(400).json({ message: "Lieu trop long (255 caractères max)" });

    try {
        if (!(await suitLePatient(req.user.id, patientId))) {
            return res.status(404).json({ message: "Patient introuvable parmi vos patients" });
        }

        const result = await db.query(
            `WITH nouveau AS (
                 INSERT INTO rendez_vous (patient_id, medecin_id, date_heure, lieu, motif)
                 VALUES ($1, $2, $3::date + $4::time, $5, $6)
                 RETURNING *
             )
             SELECT n.id, n.patient_id, u.nom_complet AS patient_nom,
                    to_char(n.date_heure, 'YYYY-MM-DD') AS date,
                    to_char(n.date_heure, 'HH24:MI') AS heure,
                    n.motif, n.lieu, n.statut
             FROM nouveau n JOIN users u ON u.id = n.patient_id`,
            [patientId, req.user.id, date, heure, l, m]
        );

        res.status(201).json({ message: "Rendez-vous ajouté", rendez_vous: result.rows[0] });
    } catch (error) {
        console.error("Erreur création rendez-vous :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// PUT /api/medecin/rendez-vous/:id/statut : « Marquer terminé » / « Annuler »
// Corps : { statut: "termine" | "annule" } ; seulement pour un rendez-vous encore planifié
exports.changerStatutRendezVous = async (req, res) => {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({ message: "Identifiant de rendez-vous invalide" });
    }
    const { statut } = req.body || {};
    if (!["termine", "annule"].includes(statut)) {
        return res.status(400).json({ message: "Statut invalide (termine ou annule)" });
    }

    try {
        const actuel = await db.query(
            "SELECT statut FROM rendez_vous WHERE id = $1 AND medecin_id = $2",
            [id, req.user.id]
        );
        if (actuel.rows.length === 0) {
            return res.status(404).json({ message: "Rendez-vous introuvable" });
        }
        if (actuel.rows[0].statut !== "planifie") {
            return res.status(400).json({ message: "Ce rendez-vous est déjà terminé ou annulé" });
        }

        await db.query("UPDATE rendez_vous SET statut = $1 WHERE id = $2", [statut, id]);
        res.json({ message: statut === "termine" ? "Rendez-vous terminé" : "Rendez-vous annulé", id, statut });
    } catch (error) {
        console.error("Erreur statut rendez-vous :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// POST /api/medecin/analyses : le médecin prescrit une analyse (pas encore d'écran)
// Corps : { patient_id, type_analyse, date: "AAAA-MM-JJ", heure: "HH:MM", laboratoire? }
exports.prescrireAnalyse = async (req, res) => {
    const { patient_id, type_analyse, date, heure, laboratoire } = req.body || {};

    const patientId = Number(patient_id);
    if (!Number.isInteger(patientId) || patientId <= 0) {
        return res.status(400).json({ message: "Le patient est obligatoire" });
    }
    const t = typeof type_analyse === "string" ? type_analyse.trim() : "";
    if (!t) return res.status(400).json({ message: "Le type d'analyse est obligatoire" });
    if (t.length > 150) return res.status(400).json({ message: "Type d'analyse trop long (150 caractères max)" });
    if (!dateValide(date)) return res.status(400).json({ message: "Date invalide (format AAAA-MM-JJ)" });
    if (!heureValide(heure)) return res.status(400).json({ message: "Heure invalide (format HH:MM)" });
    const labo = typeof laboratoire === "string" && laboratoire.trim() ? laboratoire.trim() : null;
    if (labo && labo.length > 150) return res.status(400).json({ message: "Laboratoire trop long (150 caractères max)" });

    try {
        if (!(await suitLePatient(req.user.id, patientId))) {
            return res.status(404).json({ message: "Patient introuvable parmi vos patients" });
        }

        const result = await db.query(
            `INSERT INTO analyses (patient_id, type_analyse, date_prevue, laboratoire)
             VALUES ($1, $2, $3::date + $4::time, $5)
             RETURNING id, patient_id, type_analyse,
                       to_char(date_prevue, 'YYYY-MM-DD') AS date,
                       to_char(date_prevue, 'HH24:MI') AS heure,
                       laboratoire, statut`,
            [patientId, t, date, heure, labo]
        );

        res.status(201).json({ message: "Analyse ajoutée", analyse: result.rows[0] });
    } catch (error) {
        console.error("Erreur prescription analyse :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

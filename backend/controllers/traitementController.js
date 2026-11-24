const db = require("../config/db");

// Heures de rappel automatiques selon le nombre de prises par jour
const HEURES_PAR_DEFAUT = {
    1: ["08:00"],
    2: ["08:00", "20:00"],
    3: ["08:00", "14:00", "20:00"],
    4: ["08:00", "12:00", "16:00", "20:00"],
    5: ["08:00", "11:00", "14:00", "17:00", "20:00"],
    6: ["08:00", "10:00", "12:00", "14:00", "16:00", "18:00"]
};

// Date du jour au format "AAAA-MM-JJ" (heure locale du serveur)
function aujourdhui() {
    const d = new Date();
    const mm = String(d.getMonth() + 1).padStart(2, "0");
    const jj = String(d.getDate()).padStart(2, "0");
    return `${d.getFullYear()}-${mm}-${jj}`;
}

// Vérifie qu'une date est bien au format "AAAA-MM-JJ" et existe (pas de 2026-02-31)
function dateValide(v) {
    if (typeof v !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(v)) return false;
    const d = new Date(`${v}T00:00:00Z`);
    return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === v;
}

// Requête commune : un traitement avec son nombre de prises et ses heures
const SELECT_TRAITEMENT = `
    SELECT t.id,
           t.nom_medicament AS nom,
           t.dosage,
           COUNT(r.id)::int AS fois_par_jour,
           t.date_debut AS debut,
           t.date_fin AS fin,
           t.prescrit_par,
           t.actif,
           COALESCE(
               array_agg(to_char(r.heure, 'HH24:MI') ORDER BY r.heure) FILTER (WHERE r.id IS NOT NULL),
               '{}'
           ) AS heures
    FROM traitements t
    LEFT JOIN rappels_medicament r ON r.traitement_id = t.id AND r.actif = TRUE`;

// Vérifie le corps envoyé par le formulaire "Nouveau médicament".
// Renvoie { erreur } ou { donnees }.
function verifierTraitement(body) {
    const { nom, dosage, fois_par_jour, debut, fin } = body || {};

    const n = typeof nom === "string" ? nom.trim() : "";
    const ds = typeof dosage === "string" ? dosage.trim() : "";
    if (!n || !ds) {
        return { erreur: "Le nom du médicament et le dosage sont obligatoires" };
    }
    if (n.length > 150) return { erreur: "Nom du médicament trop long (150 caractères max)" };
    if (ds.length > 50) return { erreur: "Dosage trop long (50 caractères max)" };

    const fois = Number(fois_par_jour);
    if (!Number.isInteger(fois) || !HEURES_PAR_DEFAUT[fois]) {
        return { erreur: "Nombre de prises par jour invalide (entre 1 et 6)" };
    }

    const dateDebut = debut === undefined || debut === null || debut === "" ? aujourdhui() : debut;
    if (!dateValide(dateDebut)) return { erreur: "Date de début invalide (format AAAA-MM-JJ)" };

    let dateFin = null;
    if (fin !== undefined && fin !== null && fin !== "") {
        if (!dateValide(fin)) return { erreur: "Date de fin invalide (format AAAA-MM-JJ)" };
        if (fin < dateDebut) return { erreur: "La date de fin ne peut pas être avant la date de début" };
        dateFin = fin;
    }

    return { donnees: { nom: n, dosage: ds, fois, debut: dateDebut, fin: dateFin } };
}

// Crée un traitement + ses heures de rappel (dans une transaction).
// prescritPar = id du médecin, ou null si c'est le patient qui l'ajoute.
// Servira aussi pour la route médecin (étape 3).
async function creerTraitement(patientId, prescritPar, donnees) {
    const client = await db.connect();
    try {
        await client.query("BEGIN");

        const t = await client.query(
            `INSERT INTO traitements (patient_id, prescrit_par, nom_medicament, dosage, frequence, date_debut, date_fin)
             VALUES ($1, $2, $3, $4, $5, $6, $7)
             RETURNING id`,
            [
                patientId,
                prescritPar,
                donnees.nom,
                donnees.dosage,
                `${donnees.fois} fois par jour`,
                donnees.debut,
                donnees.fin
            ]
        );
        const traitementId = t.rows[0].id;

        for (const heure of HEURES_PAR_DEFAUT[donnees.fois]) {
            await client.query(
                "INSERT INTO rappels_medicament (traitement_id, heure) VALUES ($1, $2)",
                [traitementId, heure]
            );
        }

        const result = await client.query(
            `${SELECT_TRAITEMENT} WHERE t.id = $1 GROUP BY t.id`,
            [traitementId]
        );

        await client.query("COMMIT");
        return result.rows[0];
    } catch (error) {
        await client.query("ROLLBACK");
        throw error;
    } finally {
        client.release();
    }
}

// Traitements en cours ou à venir d'un patient (pas ceux terminés ou arrêtés)
async function listeTraitements(patientId) {
    const result = await db.query(
        `${SELECT_TRAITEMENT}
         WHERE t.patient_id = $1
           AND t.actif = TRUE
           AND (t.date_fin IS NULL OR t.date_fin >= CURRENT_DATE)
         GROUP BY t.id
         ORDER BY t.date_debut DESC, t.nom_medicament`,
        [patientId]
    );
    return result.rows;
}

// ---------- Routes patient ----------

// GET /api/patients/me/traitements
exports.mesTraitements = async (req, res) => {
    try {
        const traitements = await listeTraitements(req.user.id);
        res.json({ message: "Liste des traitements", traitements });
    } catch (error) {
        console.error("Erreur liste traitements :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// POST /api/patients/me/traitements : le patient ajoute lui-même un médicament
exports.ajouterMonTraitement = async (req, res) => {
    const { erreur, donnees } = verifierTraitement(req.body);
    if (erreur) return res.status(400).json({ message: erreur });

    try {
        const traitement = await creerTraitement(req.user.id, null, donnees);
        res.status(201).json({ message: "Médicament ajouté", traitement });
    } catch (error) {
        console.error("Erreur ajout traitement :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// GET /api/patients/me/prises/aujourdhui : écran "Rappels" (onglet Médicaments) + accueil
exports.prisesDuJour = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT r.id AS rappel_id,
                    t.id AS traitement_id,
                    to_char(r.heure, 'HH24:MI') AS heure,
                    t.nom_medicament AS nom,
                    t.dosage,
                    COALESCE(p.statut = 'prise', FALSE) AS pris,
                    to_char(p.heure_prise, 'HH24:MI') AS heure_prise
             FROM traitements t
             JOIN rappels_medicament r ON r.traitement_id = t.id AND r.actif = TRUE
             LEFT JOIN prises_medicament p
                    ON p.traitement_id = t.id AND p.date_prevue = CURRENT_DATE + r.heure
             WHERE t.patient_id = $1
               AND t.actif = TRUE
               AND t.date_debut <= CURRENT_DATE
               AND (t.date_fin IS NULL OR t.date_fin >= CURRENT_DATE)
             ORDER BY r.heure, t.nom_medicament`,
            [req.user.id]
        );

        res.json({ message: "Prises du jour", date: aujourdhui(), prises: result.rows });
    } catch (error) {
        console.error("Erreur prises du jour :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// POST /api/patients/me/prises : bouton "Marquer pris"
// Corps : { rappel_id }. Si la prise est déjà marquée, rien ne change.
exports.marquerPrise = async (req, res) => {
    const rappelId = Number(req.body?.rappel_id);
    if (!Number.isInteger(rappelId) || rappelId <= 0) {
        return res.status(400).json({ message: "rappel_id est obligatoire" });
    }

    try {
        // Le rappel doit appartenir à un traitement du patient, en cours aujourd'hui
        const rappel = await db.query(
            `SELECT r.id, r.heure, t.id AS traitement_id
             FROM rappels_medicament r
             JOIN traitements t ON t.id = r.traitement_id
             WHERE r.id = $1
               AND r.actif = TRUE
               AND t.patient_id = $2
               AND t.actif = TRUE
               AND t.date_debut <= CURRENT_DATE
               AND (t.date_fin IS NULL OR t.date_fin >= CURRENT_DATE)`,
            [rappelId, req.user.id]
        );
        if (rappel.rows.length === 0) {
            return res.status(404).json({ message: "Rappel introuvable" });
        }
        const { traitement_id, heure } = rappel.rows[0];

        const result = await db.query(
            `INSERT INTO prises_medicament (traitement_id, date_prevue, statut, heure_prise)
             VALUES ($1, CURRENT_DATE + $2::time, 'prise', CURRENT_TIMESTAMP)
             ON CONFLICT (traitement_id, date_prevue) DO UPDATE
             SET statut = 'prise',
                 heure_prise = COALESCE(prises_medicament.heure_prise, CURRENT_TIMESTAMP)
             RETURNING to_char(heure_prise, 'HH24:MI') AS heure_prise`,
            [traitement_id, heure]
        );

        res.json({
            message: "Prise enregistrée",
            prise: {
                rappel_id: rappelId,
                traitement_id,
                heure: String(heure).slice(0, 5),
                pris: true,
                heure_prise: result.rows[0].heure_prise
            }
        });
    } catch (error) {
        console.error("Erreur marquer prise :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// ---------- Routes médecin ----------

// Lit :patientId dans l'URL et vérifie que le médecin suit ce patient (suivi_medical).
// Renvoie l'id du patient, ou null après avoir déjà répondu (400 / 404).
async function patientSuivi(req, res) {
    const patientId = Number(req.params.patientId);
    if (!Number.isInteger(patientId) || patientId <= 0) {
        res.status(400).json({ message: "Identifiant de patient invalide" });
        return null;
    }

    const suivi = await db.query(
        "SELECT 1 FROM suivi_medical WHERE medecin_id = $1 AND patient_id = $2",
        [req.user.id, patientId]
    );
    if (suivi.rows.length === 0) {
        // Même réponse si le patient n'existe pas ou n'est pas suivi : on ne révèle rien
        res.status(404).json({ message: "Patient introuvable parmi vos patients" });
        return null;
    }
    return patientId;
}

// GET /api/medecin/patients/:patientId/traitements : onglet "Traitements" de la fiche patient
exports.traitementsPatient = async (req, res) => {
    try {
        const patientId = await patientSuivi(req, res);
        if (patientId === null) return;

        const traitements = await listeTraitements(patientId);
        res.json({ message: "Liste des traitements", traitements });
    } catch (error) {
        console.error("Erreur traitements patient :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// POST /api/medecin/patients/:patientId/traitements : le médecin prescrit un médicament
exports.prescrireTraitement = async (req, res) => {
    try {
        const patientId = await patientSuivi(req, res);
        if (patientId === null) return;

        const { erreur, donnees } = verifierTraitement(req.body);
        if (erreur) return res.status(400).json({ message: erreur });

        const traitement = await creerTraitement(patientId, req.user.id, donnees);
        res.status(201).json({ message: "Médicament ajouté", traitement });
    } catch (error) {
        console.error("Erreur prescription :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

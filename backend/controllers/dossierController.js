const db = require("../config/db");

// Dossier médical (séance 5) : le médecin ajoute les documents, le patient les consulte.
// Pas encore de vrai fichier : seulement titre, type et date (fichier_url facultatif).

// Types acceptés (mêmes valeurs que la base)
const TYPES_DOCUMENT = ["ordonnance", "analyse", "compte_rendu", "imagerie", "autre"];

// Colonnes renvoyées pour un document
const COLONNES_DOCUMENT = `
    d.id,
    d.titre,
    d.type_document,
    d.date_document,
    d.fichier_url`;

// ---------- Routes patient ----------

// GET /api/patients/me/documents : écran « Dossier médical », du plus récent au plus ancien
exports.mesDocuments = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT ${COLONNES_DOCUMENT}
             FROM documents_medicaux d
             WHERE d.patient_id = $1
             ORDER BY d.date_document DESC, d.id DESC`,
            [req.user.id]
        );
        res.json({ message: "Documents du dossier", documents: result.rows });
    } catch (error) {
        console.error("Erreur documents patient :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// GET /api/patients/me/partages : section « Partagé avec » (médecins qui ont accès au dossier)
exports.mesPartages = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT a.professionnel_id AS medecin_id,
                    u.nom_complet AS medecin_nom,
                    p.specialite AS medecin_specialite,
                    to_char(a.date_autorisation, 'YYYY-MM-DD') AS date_autorisation
             FROM acces_dossier a
             JOIN users u ON u.id = a.professionnel_id
             LEFT JOIN professionnels p ON p.user_id = a.professionnel_id
             WHERE a.patient_id = $1
             ORDER BY u.nom_complet`,
            [req.user.id]
        );
        res.json({ message: "Dossier partagé avec", partages: result.rows });
    } catch (error) {
        console.error("Erreur partages :", error.message);
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

// Lit :patientId dans l'URL. Renvoie l'id, ou null après avoir répondu 400.
function lirePatientId(req, res) {
    const patientId = Number(req.params.patientId);
    if (!Number.isInteger(patientId) || patientId <= 0) {
        res.status(400).json({ message: "Identifiant de patient invalide" });
        return null;
    }
    return patientId;
}

// GET /api/medecin/patients/:patientId/documents : onglet « Documents » de la fiche patient
// Le patient doit avoir partagé son dossier avec ce médecin (acces_dossier).
exports.documentsPatient = async (req, res) => {
    const patientId = lirePatientId(req, res);
    if (patientId === null) return;

    try {
        const acces = await db.query(
            "SELECT 1 FROM acces_dossier WHERE patient_id = $1 AND professionnel_id = $2",
            [patientId, req.user.id]
        );
        if (acces.rows.length === 0) {
            return res.status(404).json({ message: "Dossier introuvable ou non partagé avec vous" });
        }

        const result = await db.query(
            `SELECT ${COLONNES_DOCUMENT}
             FROM documents_medicaux d
             WHERE d.patient_id = $1
             ORDER BY d.date_document DESC, d.id DESC`,
            [patientId]
        );
        res.json({ message: "Documents du dossier", documents: result.rows });
    } catch (error) {
        console.error("Erreur documents (médecin) :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// POST /api/medecin/patients/:patientId/documents : écran « Nouveau document »
// Corps : { titre, type_document, date_document? } ; seulement pour un patient suivi.
exports.ajouterDocument = async (req, res) => {
    const patientId = lirePatientId(req, res);
    if (patientId === null) return;

    const { titre, type_document, date_document } = req.body || {};
    const t = typeof titre === "string" ? titre.trim() : "";
    if (!t) return res.status(400).json({ message: "Le titre est obligatoire" });
    if (t.length > 150) return res.status(400).json({ message: "Titre trop long (150 caractères max)" });
    if (!TYPES_DOCUMENT.includes(type_document)) {
        return res.status(400).json({
            message: "Type invalide (ordonnance, analyse, compte_rendu, imagerie ou autre)"
        });
    }
    const avecDate = date_document !== undefined && date_document !== null && date_document !== "";
    if (avecDate && !dateValide(date_document)) {
        return res.status(400).json({ message: "Date invalide (format AAAA-MM-JJ)" });
    }

    try {
        const suivi = await db.query(
            "SELECT 1 FROM suivi_medical WHERE medecin_id = $1 AND patient_id = $2",
            [req.user.id, patientId]
        );
        if (suivi.rows.length === 0) {
            return res.status(404).json({ message: "Patient introuvable parmi vos patients" });
        }

        const result = await db.query(
            `INSERT INTO documents_medicaux AS d (patient_id, titre, type_document, date_document)
             VALUES ($1, $2, $3, COALESCE($4::date, CURRENT_DATE))
             RETURNING ${COLONNES_DOCUMENT}`,
            [patientId, t, type_document, avecDate ? date_document : null]
        );
        res.status(201).json({ message: "Document ajouté", document: result.rows[0] });
    } catch (error) {
        console.error("Erreur ajout document :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

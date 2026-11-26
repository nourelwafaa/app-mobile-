const db = require("../config/db");
const { SELECT_PATIENT_SUIVI } = require("./medecinController");

// Messagerie (séance 7) : uniquement entre un médecin et un patient qu'il suit (suivi_medical).
// Pas de temps réel : l'app recharge la discussion ouverte toutes les 5 secondes.
// JSON : "texte" (nom du modèle Flutter) ↔ colonne "contenu" de la base.

const TEXTE_MAX = 2000;

// Lit un id dans l'URL. Renvoie l'id, ou null après avoir répondu 400.
function lireId(valeur, res, message) {
    const id = Number(valeur);
    if (!Number.isInteger(id) || id <= 0) {
        res.status(400).json({ message });
        return null;
    }
    return id;
}

// Lit le texte du message. Renvoie le texte, ou null après avoir répondu 400.
function lireTexte(body, res) {
    const t = typeof body?.texte === "string" ? body.texte.trim() : "";
    if (!t) {
        res.status(400).json({ message: "Le message est vide" });
        return null;
    }
    if (t.length > TEXTE_MAX) {
        res.status(400).json({ message: `Message trop long (${TEXTE_MAX} caractères max)` });
        return null;
    }
    return t;
}

async function estSuivi(medecinId, patientId) {
    const r = await db.query(
        "SELECT 1 FROM suivi_medical WHERE medecin_id = $1 AND patient_id = $2",
        [medecinId, patientId]
    );
    return r.rows.length > 0;
}

// Messages entre moi et l'autre personne, du plus ancien au plus récent.
// Les messages reçus passent en « lu » (on vient d'ouvrir la discussion).
async function discussion(moiId, autreId) {
    await db.query(
        `UPDATE messages SET lu = TRUE
         WHERE expediteur_id = $2 AND destinataire_id = $1 AND lu = FALSE`,
        [moiId, autreId]
    );
    const result = await db.query(
        `SELECT id,
                (expediteur_id = $1) AS de_moi,
                contenu AS texte,
                to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS date,
                lu
         FROM messages
         WHERE (expediteur_id = $1 AND destinataire_id = $2)
            OR (expediteur_id = $2 AND destinataire_id = $1)
         ORDER BY created_at, id`,
        [moiId, autreId]
    );
    return result.rows;
}

async function envoyer(moiId, autreId, texte) {
    const result = await db.query(
        `INSERT INTO messages (expediteur_id, destinataire_id, contenu)
         VALUES ($1, $2, $3)
         RETURNING id, TRUE AS de_moi, contenu AS texte,
                   to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS date, lu`,
        [moiId, autreId, texte]
    );
    return result.rows[0];
}

// ---------- Patient ----------

// GET /api/patients/me/medecins : écran « Messages » du patient
// Médecins qui suivent le patient, avec le dernier message (null si aucun) et les non-lus.
// Plus récente discussion d'abord, puis les médecins sans message.
exports.mesMedecins = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT sm.medecin_id,
                    u.nom_complet AS medecin_nom,
                    p.specialite AS medecin_specialite,
                    (SELECT COUNT(*)::int FROM messages m
                      WHERE m.expediteur_id = sm.medecin_id AND m.destinataire_id = $1
                        AND m.lu = FALSE) AS non_lus,
                    dm.id AS dernier_id,
                    (dm.expediteur_id = $1) AS dernier_de_moi,
                    dm.contenu AS dernier_texte,
                    to_char(dm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS dernier_date,
                    dm.lu AS dernier_lu
             FROM suivi_medical sm
             JOIN users u ON u.id = sm.medecin_id
             LEFT JOIN professionnels p ON p.user_id = sm.medecin_id
             LEFT JOIN LATERAL (
                 SELECT m.* FROM messages m
                 WHERE (m.expediteur_id = $1 AND m.destinataire_id = sm.medecin_id)
                    OR (m.expediteur_id = sm.medecin_id AND m.destinataire_id = $1)
                 ORDER BY m.created_at DESC, m.id DESC
                 LIMIT 1
             ) dm ON TRUE
             WHERE sm.patient_id = $1
             ORDER BY dm.created_at DESC NULLS LAST, u.nom_complet`,
            [req.user.id]
        );

        const medecins = result.rows.map((r) => {
            const { dernier_id, dernier_de_moi, dernier_texte, dernier_date, dernier_lu, ...medecin } = r;
            return {
                ...medecin,
                dernier_message: dernier_id === null ? null
                    : { id: dernier_id, de_moi: dernier_de_moi, texte: dernier_texte, date: dernier_date, lu: dernier_lu }
            };
        });
        res.json({ message: "Mes médecins", medecins });
    } catch (error) {
        console.error("Erreur mes médecins :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// GET /api/patients/me/messages/:medecinId : discussion avec un médecin qui me suit
exports.messagesAvecMedecin = async (req, res) => {
    const medecinId = lireId(req.params.medecinId, res, "Identifiant de médecin invalide");
    if (medecinId === null) return;
    try {
        if (!(await estSuivi(medecinId, req.user.id))) {
            return res.status(403).json({ message: "Vous ne pouvez écrire qu'à un médecin qui vous suit" });
        }
        res.json({ message: "Discussion", messages: await discussion(req.user.id, medecinId) });
    } catch (error) {
        console.error("Erreur discussion patient :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// POST /api/patients/me/messages/:medecinId : { texte }
exports.ecrireAuMedecin = async (req, res) => {
    const medecinId = lireId(req.params.medecinId, res, "Identifiant de médecin invalide");
    if (medecinId === null) return;
    const texte = lireTexte(req.body, res);
    if (texte === null) return;
    try {
        if (!(await estSuivi(medecinId, req.user.id))) {
            return res.status(403).json({ message: "Vous ne pouvez écrire qu'à un médecin qui vous suit" });
        }
        res.status(201).json({ message: "Message envoyé", envoye: await envoyer(req.user.id, medecinId, texte) });
    } catch (error) {
        console.error("Erreur envoi patient :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// ---------- Médecin ----------

// GET /api/medecin/conversations : patients suivis avec au moins un message, plus récent d'abord
exports.conversations = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT * FROM (
                 SELECT patients.*,
                        dm.id AS dernier_id,
                        (dm.expediteur_id = $1) AS dernier_de_moi,
                        dm.contenu AS dernier_texte,
                        to_char(dm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS dernier_date,
                        dm.created_at AS dernier_tri,
                        dm.lu AS dernier_lu,
                        (SELECT COUNT(*)::int FROM messages m
                          WHERE m.expediteur_id = patients.id AND m.destinataire_id = $1
                            AND m.lu = FALSE) AS non_lus
                 FROM (${SELECT_PATIENT_SUIVI}) AS patients
                 JOIN LATERAL (
                     SELECT m.* FROM messages m
                     WHERE (m.expediteur_id = $1 AND m.destinataire_id = patients.id)
                        OR (m.expediteur_id = patients.id AND m.destinataire_id = $1)
                     ORDER BY m.created_at DESC, m.id DESC
                     LIMIT 1
                 ) dm ON TRUE
             ) c
             ORDER BY c.dernier_tri DESC`,
            [req.user.id]
        );

        const conversations = result.rows.map((r) => {
            const { dernier_id, dernier_de_moi, dernier_texte, dernier_date, dernier_tri, dernier_lu, non_lus, ...patient } = r;
            return {
                patient,
                dernier_message: { id: dernier_id, de_moi: dernier_de_moi, texte: dernier_texte, date: dernier_date, lu: dernier_lu },
                non_lus
            };
        });
        res.json({ message: "Conversations", conversations });
    } catch (error) {
        console.error("Erreur conversations :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// GET /api/medecin/messages/:patientId : discussion avec un patient suivi
exports.messagesAvecPatient = async (req, res) => {
    const patientId = lireId(req.params.patientId, res, "Identifiant de patient invalide");
    if (patientId === null) return;
    try {
        if (!(await estSuivi(req.user.id, patientId))) {
            return res.status(404).json({ message: "Patient introuvable parmi vos patients" });
        }
        res.json({ message: "Discussion", messages: await discussion(req.user.id, patientId) });
    } catch (error) {
        console.error("Erreur discussion médecin :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// POST /api/medecin/messages/:patientId : { texte }
exports.ecrireAuPatient = async (req, res) => {
    const patientId = lireId(req.params.patientId, res, "Identifiant de patient invalide");
    if (patientId === null) return;
    const texte = lireTexte(req.body, res);
    if (texte === null) return;
    try {
        if (!(await estSuivi(req.user.id, patientId))) {
            return res.status(404).json({ message: "Patient introuvable parmi vos patients" });
        }
        res.status(201).json({ message: "Message envoyé", envoye: await envoyer(req.user.id, patientId, texte) });
    } catch (error) {
        console.error("Erreur envoi médecin :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

const db = require("../config/db");

// Consentement du patient : le patient accepte ou refuse les demandes de suivi des médecins.
// Accepter = le médecin suit le patient (suivi_medical) et a accès à son dossier (acces_dossier).

// GET /api/patients/me/demandes : demandes en attente (bandeau de l'accueil patient)
exports.mesDemandes = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT d.id,
                    d.medecin_id,
                    u.nom_complet AS medecin_nom,
                    p.specialite AS medecin_specialite,
                    p.etablissement AS medecin_etablissement,
                    to_char(d.created_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS date
             FROM demandes_suivi d
             JOIN users u ON u.id = d.medecin_id
             LEFT JOIN professionnels p ON p.user_id = d.medecin_id
             WHERE d.patient_id = $1 AND d.statut = 'en_attente'
             ORDER BY d.created_at DESC`,
            [req.user.id]
        );
        res.json({ message: "Demandes de suivi", demandes: result.rows });
    } catch (error) {
        console.error("Erreur demandes :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// PUT /api/patients/me/demandes/:id : { decision: "accepter" | "refuser" }
exports.repondreDemande = async (req, res) => {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({ message: "Identifiant de demande invalide" });
    }
    const { decision } = req.body || {};
    if (!["accepter", "refuser"].includes(decision)) {
        return res.status(400).json({ message: "Décision invalide (accepter ou refuser)" });
    }

    const client = await db.connect();
    try {
        await client.query("BEGIN");

        // La demande doit être au patient connecté et encore en attente
        const demande = await client.query(
            `UPDATE demandes_suivi
             SET statut = $3, date_reponse = CURRENT_TIMESTAMP
             WHERE id = $1 AND patient_id = $2 AND statut = 'en_attente'
             RETURNING medecin_id`,
            [id, req.user.id, decision === "accepter" ? "acceptee" : "refusee"]
        );
        if (demande.rows.length === 0) {
            await client.query("ROLLBACK");
            return res.status(404).json({ message: "Demande introuvable ou déjà traitée" });
        }

        if (decision === "accepter") {
            const medecinId = demande.rows[0].medecin_id;
            await client.query(
                `INSERT INTO suivi_medical (medecin_id, patient_id) VALUES ($1, $2)
                 ON CONFLICT (medecin_id, patient_id) DO NOTHING`,
                [medecinId, req.user.id]
            );
            await client.query(
                `INSERT INTO acces_dossier (patient_id, professionnel_id) VALUES ($1, $2)
                 ON CONFLICT (patient_id, professionnel_id) DO NOTHING`,
                [req.user.id, medecinId]
            );
        }

        await client.query("COMMIT");
        res.json({
            message: decision === "accepter"
                ? "Demande acceptée : ce médecin vous suit maintenant"
                : "Demande refusée",
            id,
            statut: decision === "accepter" ? "acceptee" : "refusee"
        });
    } catch (error) {
        await client.query("ROLLBACK").catch(() => {});
        console.error("Erreur réponse demande :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    } finally {
        client.release();
    }
};

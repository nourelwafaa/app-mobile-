const db = require("../config/db");

// Notifications du médecin (séance 8).
// Elles sont créées à partir de ce qui se passe déjà dans l'app :
//   - message : un patient suivi lui a écrit
//   - alerte : une alerte d'un patient suivi (douleur ≥ 8…)
//   - rendez_vous : un rendez-vous commence bientôt (rappel_minutes avant, 60 par défaut)
// À chaque appel, synchroniser() ajoute les nouvelles (sans doublon grâce à ref_id)
// et marque comme lues celles dont le message a été lu ou l'alerte traitée.

async function synchroniser(medecinId) {
    // Messages des 7 derniers jours envoyés par un patient suivi
    await db.query(
        `INSERT INTO notifications (user_id, type, titre, message, patient_id, ref_id, lue, created_at)
         SELECT $1, 'message', 'Nouveau message',
                u.nom_complet || ' : ' || LEFT(m.contenu, 120),
                m.expediteur_id, m.id, m.lu, m.created_at
         FROM messages m
         JOIN suivi_medical sm ON sm.patient_id = m.expediteur_id AND sm.medecin_id = $1
         JOIN users u ON u.id = m.expediteur_id
         WHERE m.destinataire_id = $1
           AND m.created_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
         ON CONFLICT (user_id, type, ref_id) DO NOTHING`,
        [medecinId]
    );

    // Alertes des 7 derniers jours des patients suivis
    await db.query(
        `INSERT INTO notifications (user_id, type, titre, message, patient_id, ref_id, lue, created_at)
         SELECT $1, 'alerte', 'Nouvelle alerte',
                u.nom_complet || ' : ' || a.message,
                a.patient_id, a.id, a.traitee, a.created_at
         FROM alertes a
         JOIN suivi_medical sm ON sm.patient_id = a.patient_id AND sm.medecin_id = $1
         JOIN users u ON u.id = a.patient_id
         WHERE a.created_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
         ON CONFLICT (user_id, type, ref_id) DO NOTHING`,
        [medecinId]
    );

    // Rendez-vous planifiés qui commencent bientôt (rappel_minutes avant, 60 par défaut)
    await db.query(
        `INSERT INTO notifications (user_id, type, titre, message, patient_id, ref_id, date_cible, created_at)
         SELECT $1, 'rendez_vous',
                CASE WHEN COALESCE(r.rappel_minutes, 60) = 60 THEN 'Rendez-vous dans 1 heure'
                     ELSE 'Rendez-vous dans ' || r.rappel_minutes || ' minutes' END,
                u.nom_complet || ' · ' || COALESCE(NULLIF(r.motif, ''), 'Rendez-vous')
                    || ' à ' || to_char(r.date_heure, 'HH24:MI'),
                r.patient_id, r.id, r.date_heure,
                r.date_heure - make_interval(mins => COALESCE(r.rappel_minutes, 60))
         FROM rendez_vous r
         JOIN users u ON u.id = r.patient_id
         WHERE r.medecin_id = $1 AND r.statut = 'planifie'
           AND r.date_heure > CURRENT_TIMESTAMP
           AND r.date_heure <= CURRENT_TIMESTAMP + make_interval(mins => COALESCE(r.rappel_minutes, 60))
         ON CONFLICT (user_id, type, ref_id) DO NOTHING`,
        [medecinId]
    );

    // Message lu dans la discussion → notification lue
    await db.query(
        `UPDATE notifications n SET lue = TRUE
         FROM messages m
         WHERE n.user_id = $1 AND n.type = 'message' AND n.lue = FALSE
           AND m.id = n.ref_id AND m.lu = TRUE`,
        [medecinId]
    );
    // Alerte traitée → notification lue
    await db.query(
        `UPDATE notifications n SET lue = TRUE
         FROM alertes a
         WHERE n.user_id = $1 AND n.type = 'alerte' AND n.lue = FALSE
           AND a.id = n.ref_id AND a.traitee = TRUE`,
        [medecinId]
    );
}

// Nombre de notifications non lues (point de la cloche, dans GET /api/medecin/accueil)
async function nombreNonLues(medecinId) {
    await synchroniser(medecinId);
    const r = await db.query(
        "SELECT COUNT(*)::int AS n FROM notifications WHERE user_id = $1 AND lue = FALSE",
        [medecinId]
    );
    return r.rows[0].n;
}
exports.nombreNonLues = nombreNonLues;

// GET /api/medecin/notifications : les 50 plus récentes des 30 derniers jours
exports.mesNotifications = async (req, res) => {
    const medecinId = req.user.id;
    try {
        await synchroniser(medecinId);
        const result = await db.query(
            `SELECT n.id, n.type, n.titre, n.message AS description,
                    to_char(n.created_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS date,
                    n.lue AS lu, n.patient_id,
                    a.niveau,
                    to_char(n.date_cible, 'YYYY-MM-DD"T"HH24:MI:SS') AS rdv_date
             FROM notifications n
             LEFT JOIN alertes a ON n.type = 'alerte' AND a.id = n.ref_id
             WHERE n.user_id = $1
               AND n.type IN ('message', 'alerte', 'rendez_vous')
               AND n.created_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
             ORDER BY n.created_at DESC
             LIMIT 50`,
            [medecinId]
        );
        const nonLues = result.rows.filter((n) => !n.lu).length;
        res.json({ message: "Notifications", non_lues: nonLues, notifications: result.rows });
    } catch (error) {
        console.error("Erreur notifications :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// PUT /api/medecin/notifications/:id/lue
exports.marquerLue = async (req, res) => {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({ message: "Identifiant de notification invalide" });
    }
    try {
        const result = await db.query(
            "UPDATE notifications SET lue = TRUE WHERE id = $1 AND user_id = $2 RETURNING id",
            [id, req.user.id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Notification introuvable" });
        }
        res.json({ message: "Notification lue", id });
    } catch (error) {
        console.error("Erreur notification lue :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// PUT /api/medecin/notifications/lues : « Tout marquer comme lu »
exports.marquerToutesLues = async (req, res) => {
    try {
        const result = await db.query(
            "UPDATE notifications SET lue = TRUE WHERE user_id = $1 AND lue = FALSE",
            [req.user.id]
        );
        res.json({ message: "Toutes les notifications sont lues", nombre: result.rowCount });
    } catch (error) {
        console.error("Erreur notifications lues :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

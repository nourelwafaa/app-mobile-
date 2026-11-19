const db = require("../config/db");

// Transforme une note (0 à 10) envoyée par l'app en entier, ou null si invalide
function note(v) {
    const n = Math.round(Number(v));
    return Number.isFinite(n) && n >= 0 && n <= 10 ? n : null;
}

// POST /api/patients/me/suivi : écran "Suivi du jour"
// Un seul suivi par jour : s'il existe déjà, il est remplacé.
exports.enregistrerSuivi = async (req, res) => {
    const { douleur, fatigue, humeur, sommeil_heures, remarque, symptomes } = req.body;

    const d = note(douleur), f = note(fatigue), h = note(humeur);
    if (d === null || f === null || h === null) {
        return res.status(400).json({ message: "Douleur, fatigue et humeur doivent être entre 0 et 10" });
    }

    let sommeil = null;
    if (sommeil_heures !== undefined && sommeil_heures !== null && sommeil_heures !== "") {
        sommeil = Number(String(sommeil_heures).replace(",", "."));
        if (!Number.isFinite(sommeil) || sommeil < 0 || sommeil > 24) {
            return res.status(400).json({ message: "Sommeil invalide (entre 0 et 24 heures)" });
        }
    }

    const liste = Array.isArray(symptomes)
        ? [...new Set(symptomes.map((s) => String(s).trim()).filter((s) => s && s.length <= 100))]
        : [];

    const patientId = req.user.id;
    const client = await db.connect();

    try {
        await client.query("BEGIN");

        // 1. Suivi du jour (créé ou remplacé)
        const result = await client.query(
            `INSERT INTO suivi_quotidien (patient_id, douleur, fatigue, humeur, sommeil_heures, remarque)
             VALUES ($1, $2, $3, $4, $5, $6)
             ON CONFLICT (patient_id, date_suivi) DO UPDATE
             SET douleur = EXCLUDED.douleur,
                 fatigue = EXCLUDED.fatigue,
                 humeur = EXCLUDED.humeur,
                 sommeil_heures = EXCLUDED.sommeil_heures,
                 remarque = EXCLUDED.remarque,
                 created_at = CURRENT_TIMESTAMP
             RETURNING id, date_suivi, douleur, fatigue, humeur,
                       sommeil_heures::float AS sommeil_heures, remarque`,
            [patientId, d, f, h, sommeil, remarque || null]
        );

        // 2. Symptômes du jour (on remplace ceux d'aujourd'hui)
        await client.query(
            `DELETE FROM symptomes
             WHERE patient_id = $1
               AND date_symptome >= CURRENT_DATE
               AND date_symptome < CURRENT_DATE + 1`,
            [patientId]
        );
        for (const nom of liste) {
            await client.query(
                "INSERT INTO symptomes (patient_id, nom) VALUES ($1, $2)",
                [patientId, nom]
            );
        }

        // 3. Alerte pour le médecin si la douleur est forte (une seule par jour)
        if (d >= 8) {
            await client.query(
                `INSERT INTO alertes (patient_id, type, message, niveau)
                 SELECT $1, 'douleur', $2, 'eleve'
                 WHERE NOT EXISTS (
                     SELECT 1 FROM alertes
                     WHERE patient_id = $1 AND type = 'douleur'
                       AND created_at >= CURRENT_DATE
                 )`,
                [patientId, `Douleur signalée à ${d}/10 dans le suivi du jour.`]
            );
        }

        await client.query("COMMIT");

        res.status(201).json({
            message: "Suivi enregistré",
            suivi: { ...result.rows[0], symptomes: liste }
        });
    } catch (error) {
        await client.query("ROLLBACK");
        console.error("Erreur suivi :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    } finally {
        client.release();
    }
};

// GET /api/patients/me/suivi/aujourdhui : pour pré-remplir l'écran
exports.suiviDuJour = async (req, res) => {
    try {
        const suivi = await db.query(
            `SELECT id, date_suivi, douleur, fatigue, humeur,
                    sommeil_heures::float AS sommeil_heures, remarque
             FROM suivi_quotidien
             WHERE patient_id = $1 AND date_suivi = CURRENT_DATE`,
            [req.user.id]
        );

        if (suivi.rows.length === 0) {
            return res.json({ suivi: null });
        }

        const symptomes = await db.query(
            `SELECT nom FROM symptomes
             WHERE patient_id = $1
               AND date_symptome >= CURRENT_DATE
               AND date_symptome < CURRENT_DATE + 1
             ORDER BY id`,
            [req.user.id]
        );

        res.json({ suivi: { ...suivi.rows[0], symptomes: symptomes.rows.map((s) => s.nom) } });
    } catch (error) {
        console.error("Erreur suivi du jour :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// GET /api/patients/me/stats?periode=7 (ou 30, 90) : écran "Mes statistiques"
exports.statistiques = async (req, res) => {
    const periode = Number(req.query.periode || 7);
    if (![7, 30, 90].includes(periode)) {
        return res.status(400).json({ message: "Période invalide (7, 30 ou 90 jours)" });
    }
    const patientId = req.user.id;

    try {
        // 1. Une ligne par jour de la période (null si pas de suivi ce jour-là)
        const jours = await db.query(
            `SELECT to_char(j, 'YYYY-MM-DD') AS date,
                    s.douleur, s.fatigue, s.humeur,
                    s.sommeil_heures::float AS sommeil_heures
             FROM generate_series(CURRENT_DATE - ($2::int - 1), CURRENT_DATE, INTERVAL '1 day') AS j
             LEFT JOIN suivi_quotidien s
                    ON s.patient_id = $1 AND s.date_suivi = j::date
             ORDER BY j`,
            [patientId, periode]
        );

        // 2. Moyennes de la période
        const moyennes = await db.query(
            `SELECT ROUND(AVG(douleur), 1)::float AS douleur,
                    ROUND(AVG(fatigue), 1)::float AS fatigue,
                    ROUND(AVG(humeur), 1)::float AS humeur,
                    ROUND(AVG(sommeil_heures), 1)::float AS sommeil_heures,
                    COUNT(*)::int AS jours_remplis
             FROM suivi_quotidien
             WHERE patient_id = $1 AND date_suivi > CURRENT_DATE - $2::int`,
            [patientId, periode]
        );

        // 3. Symptôme le plus fréquent
        const symptome = await db.query(
            `SELECT nom, COUNT(DISTINCT date_symptome::date)::int AS jours
             FROM symptomes
             WHERE patient_id = $1 AND date_symptome >= CURRENT_DATE - ($2::int - 1)
             GROUP BY nom
             ORDER BY jours DESC, nom
             LIMIT 1`,
            [patientId, periode]
        );

        // 4. Tendance de la fatigue : période actuelle vs période précédente
        const tendance = await db.query(
            `SELECT
                ROUND(AVG(fatigue) FILTER (WHERE date_suivi > CURRENT_DATE - $2::int), 1)::float AS actuelle,
                ROUND(AVG(fatigue) FILTER (WHERE date_suivi <= CURRENT_DATE - $2::int), 1)::float AS precedente
             FROM suivi_quotidien
             WHERE patient_id = $1 AND date_suivi > CURRENT_DATE - (2 * $2::int)`,
            [patientId, periode]
        );

        const { actuelle, precedente } = tendance.rows[0];
        let evolution = null;
        if (actuelle !== null && precedente !== null) {
            evolution = actuelle < precedente ? "baisse" : actuelle > precedente ? "hausse" : "stable";
        }

        res.json({
            periode,
            jours: jours.rows,
            moyennes: moyennes.rows[0],
            symptome_frequent: symptome.rows[0] || null,
            tendance_fatigue: { actuelle, precedente, evolution }
        });
    } catch (error) {
        console.error("Erreur statistiques :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};
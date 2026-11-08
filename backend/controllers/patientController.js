const db = require("../config/db");

const SEXES = ["homme", "femme"];
const GROUPES = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

// GET /api/patients/me : profil complet du patient connecté
exports.getMonProfil = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT u.id, u.nom_complet, u.email, u.telephone, u.date_naissance, u.role, u.photo,
                    EXTRACT(YEAR FROM AGE(u.date_naissance))::int AS age,
                    p.sexe, p.poids::float AS poids, p.taille::float AS taille, p.groupe_sanguin
             FROM users u
             JOIN patients p ON p.user_id = u.id
             WHERE u.id = $1`,
            [req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Patient introuvable" });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error("Erreur profil :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};

// PUT /api/patients/me/infos : écran "Ajouter des informations"
exports.majInfos = async (req, res) => {
    const { sexe, poids, taille, groupe_sanguin } = req.body;

    // Vérifications (chaque champ est optionnel, mais doit être valide s'il est envoyé)
    if (sexe !== undefined && !SEXES.includes(sexe)) {
        return res.status(400).json({ message: "Sexe invalide (homme ou femme)" });
    }
    if (groupe_sanguin !== undefined && !GROUPES.includes(groupe_sanguin)) {
        return res.status(400).json({ message: "Groupe sanguin invalide" });
    }
    if (poids !== undefined && !(Number(poids) > 0 && Number(poids) <= 300)) {
        return res.status(400).json({ message: "Poids invalide" });
    }
    if (taille !== undefined && !(Number(taille) > 0 && Number(taille) <= 250)) {
        return res.status(400).json({ message: "Taille invalide" });
    }

    try {
        const result = await db.query(
            `UPDATE patients
             SET sexe = COALESCE($1, sexe),
                 poids = COALESCE($2, poids),
                 taille = COALESCE($3, taille),
                 groupe_sanguin = COALESCE($4, groupe_sanguin)
             WHERE user_id = $5
             RETURNING user_id, sexe, poids::float AS poids, taille::float AS taille, groupe_sanguin`,
            [sexe ?? null, poids ?? null, taille ?? null, groupe_sanguin ?? null, req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Patient introuvable" });
        }

        res.json({ message: "Informations enregistrées", infos: result.rows[0] });
    } catch (error) {
        console.error("Erreur infos patient :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};
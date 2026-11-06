const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const db = require("../config/db");

const ROLES = ["patient", "medecin"];
const ROLES_PROS = ["medecin"];

// Crée le token JWT (valable 7 jours)
function creerToken(user) {
    return jwt.sign(
        { id: user.id, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: "7d" }
    );
}

// POST /api/auth/register
exports.register = async (req, res) => {
    const { nom_complet, email, telephone, mot_de_passe, date_naissance, role } = req.body;

    // Vérifications
    if (!nom_complet || !email || !mot_de_passe || !role) {
        return res.status(400).json({ message: "Nom complet, email, mot de passe et rôle sont obligatoires" });
    }
    if (!ROLES.includes(role)) {
        return res.status(400).json({ message: "Rôle invalide" });
    }
    if (mot_de_passe.length < 6) {
        return res.status(400).json({ message: "Le mot de passe doit contenir au moins 6 caractères" });
    }

    const emailPropre = email.trim().toLowerCase();
    const client = await db.connect();

    try {
        await client.query("BEGIN");

        // Email ou téléphone déjà utilisé ?
        const existe = await client.query(
            "SELECT id FROM users WHERE email = $1 OR telephone = $2",
            [emailPropre, telephone || null]
        );
        if (existe.rows.length > 0) {
            await client.query("ROLLBACK");
            return res.status(409).json({ message: "Email ou téléphone déjà utilisé" });
        }

        // Hashage du mot de passe
        const hash = await bcrypt.hash(mot_de_passe, 10);

        // Création de l'utilisateur
        const result = await client.query(
            `INSERT INTO users (nom_complet, email, telephone, mot_de_passe, date_naissance, role)
             VALUES ($1, $2, $3, $4, $5, $6)
             RETURNING id, nom_complet, email, telephone, date_naissance, role, created_at`,
            [nom_complet, emailPropre, telephone || null, hash, date_naissance || null, role]
        );
        const user = result.rows[0];

        // Création du profil selon le rôle
        if (role === "patient") {
            await client.query("INSERT INTO patients (user_id) VALUES ($1)", [user.id]);
        } else if (ROLES_PROS.includes(role)) {
            await client.query("INSERT INTO professionnels (user_id) VALUES ($1)", [user.id]);
        }

        await client.query("COMMIT");

        res.status(201).json({
            message: "Compte créé avec succès",
            token: creerToken(user),
            user
        });
    } catch (error) {
        await client.query("ROLLBACK");
        console.error("Erreur inscription :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    } finally {
        client.release();
    }
};

// POST /api/auth/login
exports.login = async (req, res) => {
    const { identifiant, mot_de_passe } = req.body; // identifiant = email ou téléphone

    if (!identifiant || !mot_de_passe) {
        return res.status(400).json({ message: "Identifiant et mot de passe obligatoires" });
    }

    try {
        const result = await db.query(
            "SELECT * FROM users WHERE email = $1 OR telephone = $2",
            [identifiant.trim().toLowerCase(), identifiant.trim()]
        );
        const user = result.rows[0];

        if (!user || !user.mot_de_passe) {
            return res.status(401).json({ message: "Identifiant ou mot de passe incorrect" });
        }

        const ok = await bcrypt.compare(mot_de_passe, user.mot_de_passe);
        if (!ok) {
            return res.status(401).json({ message: "Identifiant ou mot de passe incorrect" });
        }

        delete user.mot_de_passe; // on ne renvoie jamais le mot de passe

        res.json({
            message: "Connexion réussie",
            token: creerToken(user),
            user
        });
    } catch (error) {
        console.error("Erreur connexion :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    }
};
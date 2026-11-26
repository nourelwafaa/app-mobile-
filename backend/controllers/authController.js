const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const db = require("../config/db");
const {
    emailValide,
    normaliserTelephone,
    telephoneValide,
    erreurMotDePasse,
    dateNaissanceValide
} = require("../utils/validation");

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
    const { nom_complet, email, telephone, mot_de_passe, date_naissance, role } = req.body || {};

    // 1. Champs obligatoires (et du bon type : du texte)
    if (typeof nom_complet !== "string" || typeof email !== "string"
        || typeof mot_de_passe !== "string" || typeof role !== "string"
        || !nom_complet.trim() || !email.trim() || !mot_de_passe) {
        return res.status(400).json({ message: "Nom complet, email, mot de passe et rôle sont obligatoires" });
    }
    if (!ROLES.includes(role)) {
        return res.status(400).json({ message: "Rôle invalide" });
    }

    // 2. Format de chaque champ
    const nom = nom_complet.trim();
    if (nom.length < 2 || nom.length > 150) {
        return res.status(400).json({ message: "Nom complet invalide (2 à 150 caractères)" });
    }
    const emailPropre = email.trim().toLowerCase();
    if (!emailValide(emailPropre)) {
        return res.status(400).json({ message: "Adresse email invalide" });
    }
    const erreurMdp = erreurMotDePasse(mot_de_passe);
    if (erreurMdp) {
        return res.status(400).json({ message: erreurMdp });
    }
    const tel = normaliserTelephone(telephone);
    if (tel !== null && !telephoneValide(tel)) {
        return res.status(400).json({ message: "Numéro de téléphone invalide (8 à 15 chiffres)" });
    }
    const avecDate = date_naissance !== undefined && date_naissance !== null && date_naissance !== "";
    if (avecDate && !dateNaissanceValide(date_naissance)) {
        return res.status(400).json({ message: "Date de naissance invalide" });
    }

    const client = await db.connect();

    try {
        await client.query("BEGIN");

        // Email ou téléphone déjà utilisé ?
        const existe = await client.query(
            "SELECT id FROM users WHERE email = $1 OR telephone = $2",
            [emailPropre, tel]
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
            [nom, emailPropre, tel, hash, avecDate ? date_naissance : null, role]
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
        await client.query("ROLLBACK").catch(() => {});
        // Deux inscriptions en même temps avec le même email/téléphone
        if (error.code === "23505") {
            return res.status(409).json({ message: "Email ou téléphone déjà utilisé" });
        }
        console.error("Erreur inscription :", error.message);
        res.status(500).json({ message: "Erreur serveur" });
    } finally {
        client.release();
    }
};

// POST /api/auth/login
// Protégé contre les essais en boucle (10 échecs / 15 min, voir authRoutes.js).
exports.login = async (req, res) => {
    const { identifiant, mot_de_passe } = req.body || {}; // identifiant = email ou téléphone

    if (typeof identifiant !== "string" || typeof mot_de_passe !== "string"
        || !identifiant.trim() || !mot_de_passe) {
        return res.status(400).json({ message: "Identifiant et mot de passe obligatoires" });
    }

    // Email → en minuscules ; téléphone → seulement les chiffres ("0661 23 45 67" = "0661234567")
    const saisie = identifiant.trim();
    const estEmail = saisie.includes("@");
    const valeur = estEmail ? saisie.toLowerCase() : normaliserTelephone(saisie);

    // Pas la peine d'interroger la base pour une saisie impossible
    if (!valeur || mot_de_passe.length > 72) {
        return res.status(401).json({ message: "Identifiant ou mot de passe incorrect" });
    }

    try {
        const result = await db.query(
            estEmail
                ? "SELECT * FROM users WHERE email = $1"
                : "SELECT * FROM users WHERE telephone = $1",
            [valeur]
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

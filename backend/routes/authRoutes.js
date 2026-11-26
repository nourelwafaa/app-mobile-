const express = require("express");
const rateLimit = require("express-rate-limit");
const router = express.Router();
const authController = require("../controllers/authController");

// Connexion : 10 essais ratés maximum en 15 minutes (par adresse IP).
// Les connexions réussies ne comptent pas.
const limiteConnexion = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 10,
    skipSuccessfulRequests: true,
    standardHeaders: "draft-7",
    legacyHeaders: false,
    message: { message: "Trop de tentatives de connexion. Réessayez dans 15 minutes." }
});

// Inscription : 20 comptes maximum par heure (par adresse IP), contre la création en masse.
const limiteInscription = rateLimit({
    windowMs: 60 * 60 * 1000,
    limit: 20,
    standardHeaders: "draft-7",
    legacyHeaders: false,
    message: { message: "Trop d'inscriptions depuis cet appareil. Réessayez plus tard." }
});

router.post("/register", limiteInscription, authController.register);
router.post("/login", limiteConnexion, authController.login);

module.exports = router;

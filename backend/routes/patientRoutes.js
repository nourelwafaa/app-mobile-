const express = require("express");
const router = express.Router();
const { verifierToken, autoriserRoles } = require("../middleware/authMiddleware");
const patientController = require("../controllers/patientController");
const suiviController = require("../controllers/suiviController");
const traitementController = require("../controllers/traitementController");

// Toutes ces routes : connecté + rôle patient
router.use(verifierToken, autoriserRoles("patient"));

// Profil
router.get("/me", patientController.getMonProfil);
router.put("/me/infos", patientController.majInfos);

// Suivi du jour + statistiques
router.post("/me/suivi", suiviController.enregistrerSuivi);
router.get("/me/suivi/aujourdhui", suiviController.suiviDuJour);
router.get("/me/stats", suiviController.statistiques);

// Traitements + prises du jour (séance 3)
router.get("/me/traitements", traitementController.mesTraitements);
router.post("/me/traitements", traitementController.ajouterMonTraitement);
router.get("/me/prises/aujourdhui", traitementController.prisesDuJour);
router.post("/me/prises", traitementController.marquerPrise);

module.exports = router;
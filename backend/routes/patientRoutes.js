const express = require("express");
const router = express.Router();
const { verifierToken, autoriserRoles } = require("../middleware/authMiddleware");
const patientController = require("../controllers/patientController");
const suiviController = require("../controllers/suiviController");
const traitementController = require("../controllers/traitementController");
const agendaController = require("../controllers/agendaController");

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

// Rendez-vous + analyses à venir (séance 4 ; créés par le médecin)
router.get("/me/rendez-vous", agendaController.mesRendezVous);
router.get("/me/analyses", agendaController.mesAnalyses);

module.exports = router;
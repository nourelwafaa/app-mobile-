const express = require("express");
const router = express.Router();
const { verifierToken, autoriserRoles } = require("../middleware/authMiddleware");
const traitementController = require("../controllers/traitementController");
const agendaController = require("../controllers/agendaController");

// Toutes ces routes : connecté + rôle médecin
router.use(verifierToken, autoriserRoles("medecin"));

// Traitements d'un patient suivi (séance 3)
router.get("/patients/:patientId/traitements", traitementController.traitementsPatient);
router.post("/patients/:patientId/traitements", traitementController.prescrireTraitement);

// Patients suivis (version simple, complétée en séance 6)
router.get("/patients", agendaController.mesPatients);

// Agenda : rendez-vous + analyses (séance 4)
router.get("/rendez-vous", agendaController.agendaMedecin);
router.post("/rendez-vous", agendaController.creerRendezVous);
router.put("/rendez-vous/:id/statut", agendaController.changerStatutRendezVous);
router.post("/analyses", agendaController.prescrireAnalyse);

module.exports = router;

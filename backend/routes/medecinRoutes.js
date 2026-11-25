const express = require("express");
const router = express.Router();
const { verifierToken, autoriserRoles } = require("../middleware/authMiddleware");
const traitementController = require("../controllers/traitementController");

// Toutes ces routes : connecté + rôle médecin
router.use(verifierToken, autoriserRoles("medecin"));

// Traitements d'un patient suivi (séance 3)
router.get("/patients/:patientId/traitements", traitementController.traitementsPatient);
router.post("/patients/:patientId/traitements", traitementController.prescrireTraitement);

module.exports = router;

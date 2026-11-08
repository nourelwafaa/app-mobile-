const express = require("express");
const router = express.Router();
const { verifierToken, autoriserRoles } = require("../middleware/authMiddleware");
const patientController = require("../controllers/patientController");

// Toutes ces routes : connecté + rôle patient
router.use(verifierToken, autoriserRoles("patient"));

router.get("/me", patientController.getMonProfil);
router.put("/me/infos", patientController.majInfos);

module.exports = router;
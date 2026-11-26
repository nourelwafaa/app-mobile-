const express = require("express");
const router = express.Router();
const { verifierToken, autoriserRoles } = require("../middleware/authMiddleware");
const traitementController = require("../controllers/traitementController");
const agendaController = require("../controllers/agendaController");
const dossierController = require("../controllers/dossierController");
const medecinController = require("../controllers/medecinController");
const messagesController = require("../controllers/messagesController");

// Toutes ces routes : connecté + rôle médecin
router.use(verifierToken, autoriserRoles("medecin"));

// Traitements d'un patient suivi (séance 3)
router.get("/patients/:patientId/traitements", traitementController.traitementsPatient);
router.post("/patients/:patientId/traitements", traitementController.prescrireTraitement);

// Patients suivis : liste, recherche, ajout, un patient (séance 6)
// (« /patients/recherche » doit rester avant « /patients/:patientId »)
router.get("/patients", medecinController.mesPatients);
router.get("/patients/recherche", medecinController.rechercherPatient);
router.post("/patients", medecinController.ajouterPatient);
router.get("/patients/:patientId", medecinController.unPatient);

// Alertes des patients suivis (séance 6)
router.get("/alertes", medecinController.mesAlertes);
router.put("/alertes/:id/traitee", medecinController.traiterAlerte);

// Accueil + profil du médecin (séance 6)
router.get("/accueil", medecinController.accueil);
router.get("/profil", medecinController.monProfil);
router.put("/profil", medecinController.majProfil);

// Messagerie avec les patients suivis (séance 7)
router.get("/conversations", messagesController.conversations);
router.get("/messages/:patientId", messagesController.messagesAvecPatient);
router.post("/messages/:patientId", messagesController.ecrireAuPatient);

// Agenda : rendez-vous + analyses (séance 4)
router.get("/rendez-vous", agendaController.agendaMedecin);
router.post("/rendez-vous", agendaController.creerRendezVous);
router.put("/rendez-vous/:id/statut", agendaController.changerStatutRendezVous);
router.post("/analyses", agendaController.prescrireAnalyse);

// Dossier médical d'un patient (séance 5)
router.get("/patients/:patientId/documents", dossierController.documentsPatient);
router.post("/patients/:patientId/documents", dossierController.ajouterDocument);

module.exports = router;

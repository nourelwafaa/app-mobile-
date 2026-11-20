import '../models/home_data.dart';
import '../models/medecin_profile.dart';
import '../models/models.dart'; // AppUser (the logged-in account)
import '../models/patient.dart';
import '../models/rendez_vous.dart';
import 'package:flutter/foundation.dart';
import '../models/document_medical.dart';
import '../models/traitement.dart';


// Gives the data to the screens.
// For now the data is FAKE. When the backend is ready, only the inside of
// these methods changes (they will call the API); the screens stay the same.
class MedecinService {
  // Incremented each time an appointment changes, so the Agenda reloads
  // even when the change was made from another screen.
  static final ValueNotifier<int> rdvChanged = ValueNotifier<int>(0);
  // The doctor's profile, kept in memory for the whole app session.
  // "static" = one single copy shared by the whole app.
  static MedecinProfile? _profile;

  // Email of the account this profile belongs to.
  static String? _profileEmail;

  // Returns the stored profile, or builds a new one from the logged-in account.
  // Like the real backend after sign-up: only name, email and phone are known,
  // the other fields start empty ("Non renseigné").
  MedecinProfile _profileFor(AppUser user) {
    // First call, or a DIFFERENT account logged in: start from scratch.
    if (_profile == null || _profileEmail != user.email) {
      _profile = MedecinProfile(
        nomComplet: user.nomComplet,
        email: user.email,
        telephone: user.telephone,
      );
      _profileEmail = user.email;
    }
    return _profile!;
  }

  // Data of the home page.
  Future<HomeData> getHomeData(AppUser user) async {
    // Waits half a second to imitate a real network call.
    await Future.delayed(const Duration(milliseconds: 500));

    // The 3 most recently active patients.
    final recents = List.of(_patients)
      ..sort((a, b) => b.derniereActivite.compareTo(a.derniereActivite));

    return HomeData(
      // The name comes from the profile, so an edit is also seen here.
      nomMedecin: _profileFor(user).nomComplet,
      patientsSuivis: _patients.length,
      alertesAujourdhui:
          _patients.where((p) => p.alerte != NiveauAlerte.aucune).length,
      rendezVousAVenir: 5,
      ameliorationMoyenne: 12,
      patientsRecents: recents.take(3).toList(),
    );
  }

  // Data of the profile page.
  Future<MedecinProfile> getProfile(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _profileFor(user);
  }

  // Saves the edited profile.
  // Memory only for now; later it will call the backend.
  Future<void> updateProfile(MedecinProfile newProfile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profile = newProfile;
    _profileEmail = newProfile.email; // the email is never changed by an edit
  }

  // ---------- Agenda (fake data, kept in memory) ----------

  // Patients the doctor can pick when creating an appointment.
  // The doctor's patients (fake data).
  static final List<Patient> _patients = _creerPatients();

  static List<Patient> _creerPatients() {
    final n = DateTime.now();
    // Date "decalage" days from today, at hour h and minute m.
    DateTime jour(int decalage, int h, int m) =>
        DateTime(n.year, n.month, n.day + decalage, h, m);

    return [
      Patient(
        id: 1,
        nom: 'Sarah Benali',
        derniereActivite: jour(0, 9, 12),
        dateNaissance: DateTime(2000, 5, 15),
        sexe: 'Femme',
        groupeSanguin: 'AB+',
        alerte: NiveauAlerte.eleve,
        messageAlerte: "Douleur 8/10 signalée aujourd'hui",
        douleur7Jours: [4, 5, 6, 5, 6, 7, 8],
      ),
      Patient(
        id: 2,
        nom: 'Maya Dubois',
        derniereActivite: jour(-1, 16, 45),
        dateNaissance: DateTime(1992, 3, 10),
        sexe: 'Femme',
        groupeSanguin: 'O+',
        douleur7Jours: [3, 4, 3, 2, 3, 3, 2],
      ),
      Patient(
        id: 3,
        nom: 'Amira Haddad',
        derniereActivite: jour(-1, 14, 20),
        dateNaissance: DateTime(1997, 8, 22),
        sexe: 'Femme',
        groupeSanguin: 'A+',
        alerte: NiveauAlerte.moyen,
        messageAlerte: 'Douleur en hausse depuis 3 jours',
        douleur7Jours: [5, 5, 6, 6, 5, 6, 7],
      ),
      Patient(
        id: 4,
        nom: 'Lina Mansouri',
        derniereActivite: jour(-3, 8, 30),
        dateNaissance: DateTime(1985, 2, 3),
        sexe: 'Femme',
        groupeSanguin: 'B+',
        douleur7Jours: [2, 3, 2, 2, 3, 2, 2],
      ),
      Patient(
        id: 5,
        nom: 'Yasmine Kaci',
        derniereActivite: jour(-4, 18, 10),
        dateNaissance: DateTime(2004, 7, 19),
        sexe: 'Femme',
        groupeSanguin: 'O-',
        douleur7Jours: [1, 2, 2, 3, 2, 1, 2],
      ),
      Patient(
        id: 6,
        nom: 'Nadia Cherif',
        derniereActivite: jour(-5, 11, 5),
        dateNaissance: DateTime(1989, 1, 27),
        sexe: 'Femme',
        groupeSanguin: 'A-',
        alerte: NiveauAlerte.moyen,
        messageAlerte: 'Sommeil insuffisant depuis 3 jours',
        douleur7Jours: [3, 4, 4, 5, 5, 5, 6],
      ),
      Patient(
        id: 7,
        nom: 'Karim Bensalem',
        derniereActivite: jour(-6, 15, 40),
        dateNaissance: DateTime(1981, 6, 5),
        sexe: 'Homme',
        groupeSanguin: 'B-',
        douleur7Jours: [2, 2, 3, 2, 2, 2, 3],
      ),
      Patient(
        id: 8,
        nom: 'Sofia Meziane',
        derniereActivite: jour(-8, 10, 0),
        dateNaissance: DateTime(1995, 9, 30),
        sexe: 'Femme',
        groupeSanguin: 'AB-',
        douleur7Jours: [4, 3, 3, 4, 3, 3, 4],
      ),
    ];
  }

  // Treatments by patient id (fake data).
  static final Map<int, List<Traitement>> _traitements = _creerTraitements();
  static int _prochainIdTraitement = 100;

  static Map<int, List<Traitement>> _creerTraitements() {
    final n = DateTime.now();
    final debut = DateTime(n.year, n.month - 3, 1);
    return {
      1: [
        Traitement(id: 1, nom: 'Plaquenil', dosage: '200 mg', foisParJour: 2, debut: debut),
        Traitement(id: 2, nom: 'Cortancyl', dosage: '5 mg', foisParJour: 1, debut: debut),
      ],
      2: [
        Traitement(id: 3, nom: 'Plaquenil', dosage: '200 mg', foisParJour: 2, debut: debut),
      ],
      3: [
        Traitement(id: 4, nom: 'Plaquenil', dosage: '200 mg', foisParJour: 2, debut: debut),
        Traitement(id: 5, nom: 'Imurel', dosage: '50 mg', foisParJour: 1, debut: debut),
      ],
    };
  }

  // Documents by patient id (fake data).
  static final Map<int, List<DocumentMedical>> _documents = _creerDocuments();
  static int _prochainIdDocument = 100;

  static Map<int, List<DocumentMedical>> _creerDocuments() {
    return {
      1: [
        DocumentMedical(id: 1, titre: 'Ordonnance Plaquenil', type: TypeDocument.ordonnance, date: DateTime(2026, 11, 2)),
        DocumentMedical(id: 2, titre: 'Bilan sanguin complet', type: TypeDocument.analyse, date: DateTime(2026, 10, 20)),
        DocumentMedical(id: 3, titre: 'Compte rendu de consultation', type: TypeDocument.compteRendu, date: DateTime(2026, 10, 14)),
        DocumentMedical(id: 4, titre: 'Radio des mains', type: TypeDocument.imagerie, date: DateTime(2026, 9, 1)),
      ],
      2: [
        DocumentMedical(id: 5, titre: 'Ordonnance Plaquenil', type: TypeDocument.ordonnance, date: DateTime(2026, 10, 5)),
      ],
      3: [
        DocumentMedical(id: 6, titre: 'Bilan sanguin complet', type: TypeDocument.analyse, date: DateTime(2026, 10, 28)),
        DocumentMedical(id: 7, titre: 'Ordonnance Imurel', type: TypeDocument.ordonnance, date: DateTime(2026, 10, 12)),
      ],
    };
  }

  // Next id for a new appointment.
  static int _prochainIdRdv = 100;

  // Fake appointments around today (so dots appear on several days).
  static final List<RendezVous> _rdvs = _creerRdvs();

  static List<RendezVous> _creerRdvs() {
    final n = DateTime.now();
    // Date at "decalage" days from today, at hour h and minute m.
    DateTime jour(int decalage, int h, int m) =>
        DateTime(n.year, n.month, n.day + decalage, h, m);

    return [
      RendezVous(
        id: 1,
        patientId: 2,
        patientNom: 'Maya Dubois',
        dateHeure: jour(0, 9, 0),
        motif: 'Contrôle trimestriel',
        statut: StatutRdv.termine,
      ),
      RendezVous(
        id: 2,
        patientId: 1,
        patientNom: 'Sarah Benali',
        dateHeure: jour(0, 10, 30),
        motif: 'Consultation de suivi',
        statut: StatutRdv.planifie,
      ),
      RendezVous(
        id: 3,
        patientId: 4,
        patientNom: 'Lina Mansouri',
        dateHeure: jour(0, 14, 0),
        motif: "Résultats d'analyses",
        statut: StatutRdv.planifie,
      ),
      RendezVous(
        id: 4,
        patientId: 3,
        patientNom: 'Amira Haddad',
        dateHeure: jour(-2, 11, 0),
        motif: 'Bilan annuel',
        statut: StatutRdv.termine,
      ),
      RendezVous(
        id: 5,
        patientId: 1,
        patientNom: 'Sarah Benali',
        dateHeure: jour(1, 15, 30),
        motif: 'Renouvellement ordonnance',
        statut: StatutRdv.planifie,
      ),
      RendezVous(
        id: 6,
        patientId: 2,
        patientNom: 'Maya Dubois',
        dateHeure: jour(3, 9, 30),
        motif: 'Douleurs articulaires',
        statut: StatutRdv.planifie,
      ),
    ];
  }

  Future<List<Patient>> getPatients() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.of(_patients);
  }

  Future<List<RendezVous>> getRendezVous() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.of(_rdvs);
  }

  Future<void> addRendezVous({
    required Patient patient,
    required DateTime dateHeure,
    required String motif,
    String? lieu,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _rdvs.add(
      RendezVous(
        id: _prochainIdRdv++,
        patientId: patient.id,
        patientNom: patient.nom,
        dateHeure: dateHeure,
        motif: motif,
        lieu: lieu,
        statut: StatutRdv.planifie,
      ),
    );
    rdvChanged.value++;
  }

  Future<void> updateStatutRdv(int id, StatutRdv statut) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final i = _rdvs.indexWhere((r) => r.id == id);
    if (i != -1) _rdvs[i] = _rdvs[i].copyWith(statut: statut);
    rdvChanged.value++;
  }

  // Ids of patients with a non-cancelled appointment this week (Mon-Sun).
  Future<Set<int>> getPatientsAvecRdvSemaine() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final n = DateTime.now();
    final lundi = DateTime(n.year, n.month, n.day - (n.weekday - 1));
    final lundiSuivant = DateTime(lundi.year, lundi.month, lundi.day + 7);
    return _rdvs
        .where((r) =>
            r.statut != StatutRdv.annule &&
            !r.dateHeure.isBefore(lundi) &&
            r.dateHeure.isBefore(lundiSuivant))
        .map((r) => r.patientId)
        .toSet();
  }

  Future<List<Traitement>> getTraitements(int patientId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.of(_traitements[patientId] ?? []);
  }

  Future<void> addTraitement({
    required int patientId,
    required String nom,
    required String dosage,
    required int foisParJour,
    required DateTime debut,
    DateTime? fin,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _traitements.putIfAbsent(patientId, () => []).add(
          Traitement(
            id: _prochainIdTraitement++,
            nom: nom,
            dosage: dosage,
            foisParJour: foisParJour,
            debut: debut,
            fin: fin,
          ),
        );
  }

  // Documents of a patient, newest first.
  Future<List<DocumentMedical>> getDocuments(int patientId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final liste = List.of(_documents[patientId] ?? <DocumentMedical>[]);
    liste.sort((a, b) => b.date.compareTo(a.date));
    return liste;
  }

  Future<void> addDocument({
    required int patientId,
    required String titre,
    required TypeDocument type,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _documents.putIfAbsent(patientId, () => []).add(
          DocumentMedical(
            id: _prochainIdDocument++,
            titre: titre,
            type: type,
            date: date,
          ),
        );
  }
}
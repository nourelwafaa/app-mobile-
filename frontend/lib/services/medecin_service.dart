import '../models/alerte.dart';
import '../models/home_data.dart';
import '../models/medecin_profile.dart';
import '../models/models.dart'; // AppUser (the logged-in account)
import '../models/patient.dart';
import '../models/rendez_vous.dart';
import 'package:flutter/foundation.dart';
import '../models/document_medical.dart';
import '../models/traitement.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/resultat_recherche.dart';


// A request to show a given day in the Agenda (a new object each time,
// so listeners are notified even when the day is the same as before).
class DemandeJour {
  final DateTime jour;

  DemandeJour(this.jour);
}

// A patient registered in the app, with his contact (fake registry).
class _Inscrit {
  final Patient patient;
  final String email;
  final String telephone;

  _Inscrit({
    required this.patient,
    required this.email,
    required this.telephone,
  });
}
// Gives the data to the screens.
// For now the data is FAKE. When the backend is ready, only the inside of
// these methods changes (they will call the API); the screens stay the same.
class MedecinService {
  // Incremented each time an appointment changes, so the Agenda reloads
  // even when the change was made from another screen.
  static final ValueNotifier<int> rdvChanged = ValueNotifier<int>(0);
  // The doctor's profile, kept in memory for the whole app session.
  // "static" = one single copy shared by the whole app.
  // Incremented each time a message is sent or read, so the lists reload.
  static final ValueNotifier<int> messagesChanged = ValueNotifier<int>(0);
  // Incremented each time a patient is added, so the lists and counters reload.
  static final ValueNotifier<int> patientsChanged = ValueNotifier<int>(0);
  // Incremented each time an alert is handled, so the lists and counters reload.
  static final ValueNotifier<int> alertesChanged = ValueNotifier<int>(0);
  // Incremented each time a notification is read (vraies notifications : espace_medecin_service.dart).
  static final ValueNotifier<int> notificationsChanged = ValueNotifier<int>(0);

  // Set by the Accueil/Notifications to open the Agenda on a given day.
  static final ValueNotifier<DemandeJour?> agendaJour =
      ValueNotifier<DemandeJour?>(null);
  // Messages by patient id, oldest first (fake data).
  static final Map<int, List<Message>> _messages = _creerMessages();
  static int _prochainIdMessage = 100;

  static Map<int, List<Message>> _creerMessages() {
    final n = DateTime.now();
    // Date "decalage" days from today, at hour h and minute m.
    DateTime jour(int decalage, int h, int m) =>
        DateTime(n.year, n.month, n.day + decalage, h, m);

    return {
      // Sarah: last message unread.
      1: [
        Message(
          id: 1,
          deMoi: false,
          texte: "Bonjour docteur, j'ai noté une douleur à 8/10 ce matin aux genoux.",
          date: jour(0, 8, 40),
          lu: true,
        ),
        Message(
          id: 2,
          deMoi: true,
          texte: "Bonjour Sarah, j'ai vu l'alerte. Avez-vous bien pris le Plaquenil hier soir ?",
          date: jour(0, 9, 5),
          lu: true,
        ),
        Message(
          id: 3,
          deMoi: false,
          texte: 'Oui, les 3 prises.',
          date: jour(0, 9, 7),
          lu: false,
        ),
      ],
      // Maya: all read.
      2: [
        Message(
          id: 6,
          deMoi: true,
          texte: 'Votre dernier bilan est bon, on se revoit jeudi.',
          date: jour(-1, 16, 30),
          lu: true,
        ),
        Message(
          id: 7,
          deMoi: false,
          texte: 'Merci docteur, à jeudi !',
          date: jour(-1, 16, 45),
          lu: true,
        ),
      ],
      // Amira: last message unread.
      3: [
        Message(
          id: 4,
          deMoi: true,
          texte: 'Bonjour Amira, pensez à bien noter votre suivi chaque soir.',
          date: jour(-2, 10, 0),
          lu: true,
        ),
        Message(
          id: 5,
          deMoi: false,
          texte: "J'ai oublié mon traitement hier soir, que dois-je faire ?",
          date: jour(-1, 21, 5),
          lu: false,
        ),
      ],
      // Lina: the doctor wrote last.
      4: [
        Message(
          id: 8,
          deMoi: false,
          texte: "Bonjour docteur, avez-vous reçu mes résultats d'analyses ?",
          date: jour(-4, 9, 30),
          lu: true,
        ),
        Message(
          id: 9,
          deMoi: true,
          texte: 'Les résultats sont bons.',
          date: jour(-4, 11, 10),
          lu: true,
        ),
      ],
    };
  }
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
      // Alerts still to handle.
      alertesAujourdhui: _alertes.where((a) => !a.traitee).length,
      // Planned appointments that have not happened yet.
      rendezVousAVenir: _rdvs
          .where((r) =>
              r.statut == StatutRdv.planifie && r.dateHeure.isAfter(DateTime.now()))
          .length,
      ameliorationMoyenne: 12,
      patientsRecents: recents.take(3).map(_avecAlerte).toList(),
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
    return _patients.map(_avecAlerte).toList();
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

  // ---------- Messages (fake data, kept in memory) ----------

  // Conversations (patients with at least one message), newest first.
  Future<List<Conversation>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final liste = <Conversation>[];
    for (final p in _patients) {
      final msgs = _messages[p.id];
      if (msgs == null || msgs.isEmpty) continue;
      liste.add(
        Conversation(
          patient: _avecAlerte(p),
          dernierMessage: msgs.last,
          nonLus: msgs.where((m) => !m.deMoi && !m.lu).length,
        ),
      );
    }
    liste.sort(
      (a, b) => b.dernierMessage.date.compareTo(a.dernierMessage.date),
    );
    return liste;
  }

  // Messages of one conversation, oldest first.
  Future<List<Message>> getMessages(int patientId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.of(_messages[patientId] ?? <Message>[]);
  }

  Future<void> envoyerMessage(int patientId, String texte) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _messages.putIfAbsent(patientId, () => []).add(
          Message(
            id: _prochainIdMessage++,
            deMoi: true,
            texte: texte,
            date: DateTime.now(),
            lu: true,
          ),
        );
    messagesChanged.value++;
  }

  // Marks all the patient's messages as read.
  void marquerLu(int patientId) {
    var change = false;
    for (final m in _messages[patientId] ?? <Message>[]) {
      if (!m.deMoi && !m.lu) {
        m.lu = true;
        change = true;
      }
    }
    if (change) messagesChanged.value++;
  }

  // Total of unread messages (for the dot on the Accueil).
  int nombreNonLus() {
    var total = 0;
    for (final msgs in _messages.values) {
      total += msgs.where((m) => !m.deMoi && !m.lu).length;
    }
    return total;
  }
  // ---------- Add a patient (fake registry, kept in memory) ----------

  // Patients registered in the app: 2 are already followed, 4 are not.
  static final List<_Inscrit> _inscrits = _creerInscrits();

  static List<_Inscrit> _creerInscrits() {
    final n = DateTime.now();
    DateTime jour(int decalage, int h, int m) =>
        DateTime(n.year, n.month, n.day + decalage, h, m);

    return [
      // Already in the doctor's list.
      _Inscrit(
        patient: _patients.firstWhere((p) => p.id == 1),
        email: 'sarah@mail.com',
        telephone: '0555 12 34 56',
      ),
      _Inscrit(
        patient: _patients.firstWhere((p) => p.id == 2),
        email: 'maya.dubois@mail.com',
        telephone: '0550 11 22 33',
      ),
      // Not followed yet.
      _Inscrit(
        patient: Patient(
          id: 9,
          nom: 'Rania Ouali',
          derniereActivite: jour(-1, 20, 15),
          dateNaissance: DateTime(1993, 4, 8),
          sexe: 'Femme',
          groupeSanguin: 'A+',
          douleur7Jours: [3, 3, 4, 3, 2, 3, 3],
        ),
        email: 'rania.ouali@mail.com',
        telephone: '0661 23 45 67',
      ),
      _Inscrit(
        patient: Patient(
          id: 10,
          nom: 'Samir Hamdi',
          derniereActivite: jour(-2, 9, 45),
          dateNaissance: DateTime(1990, 11, 12),
          sexe: 'Homme',
          groupeSanguin: 'B+',
          douleur7Jours: [2, 3, 2, 2, 3, 3, 2],
        ),
        email: 'samir.hamdi@mail.com',
        telephone: '0770 98 76 54',
      ),
      _Inscrit(
        patient: Patient(
          id: 11,
          nom: 'Lydia Bouzid',
          derniereActivite: jour(-3, 19, 30),
          dateNaissance: DateTime(1999, 2, 17),
          sexe: 'Femme',
          groupeSanguin: 'O+',
          douleur7Jours: [4, 4, 5, 4, 4, 5, 4],
        ),
        email: 'lydia.bouzid@mail.com',
        telephone: '0555 44 33 22',
      ),
      _Inscrit(
        patient: Patient(
          id: 12,
          nom: 'Nabil Taleb',
          derniereActivite: jour(-5, 8, 20),
          dateNaissance: DateTime(1978, 6, 30),
          sexe: 'Homme',
          groupeSanguin: 'AB+',
          douleur7Jours: [1, 2, 1, 2, 2, 1, 2],
        ),
        email: 'nabil.taleb@mail.com',
        telephone: '0698 11 00 99',
      ),
    ];
  }

  // Looks for a registered patient by exact email or phone number.
  // Returns null if nobody matches.
  Future<ResultatRecherche?> rechercherPatient(String identifiant) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final saisie = identifiant.trim().toLowerCase();
    final estEmail = saisie.contains('@');
    // Phone compared without spaces or dashes.
    final chiffres = saisie.replaceAll(RegExp(r'\D'), '');

    for (final i in _inscrits) {
      final memeEmail = estEmail && i.email.toLowerCase() == saisie;
      final memeTel = !estEmail &&
          chiffres.length >= 8 &&
          i.telephone.replaceAll(RegExp(r'\D'), '') == chiffres;

      if (memeEmail || memeTel) {
        return ResultatRecherche(
          patient: i.patient,
          dejaSuivi: _patients.any((p) => p.id == i.patient.id),
        );
      }
    }
    return null;
  }

  // Adds a patient to the doctor's list.
  Future<void> ajouterPatient(Patient patient) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_patients.any((p) => p.id == patient.id)) return;
    _patients.add(patient);
    patientsChanged.value++;
  }
  // ---------- Alerts (fake data, kept in memory) ----------

  static final List<Alerte> _alertes = _creerAlertes();

  static List<Alerte> _creerAlertes() {
    final n = DateTime.now();
    DateTime jour(int decalage, int h, int m) =>
        DateTime(n.year, n.month, n.day + decalage, h, m);

    return [
      Alerte(
        id: 1,
        patientId: 1,
        patientNom: 'Sarah Benali',
        niveau: NiveauAlerte.eleve,
        message: 'Douleur signalée à 8/10 dans le suivi du jour.',
        date: jour(0, 9, 12),
      ),
      Alerte(
        id: 2,
        patientId: 3,
        patientNom: 'Amira Haddad',
        niveau: NiveauAlerte.moyen,
        message: '2 prises de Plaquenil oubliées cette semaine.',
        date: jour(-1, 20, 30),
      ),
      Alerte(
        id: 3,
        patientId: 2,
        patientNom: 'Maya Dubois',
        niveau: NiveauAlerte.faible,
        message: 'Fatigue en hausse depuis 3 jours.',
        date: jour(-1, 16, 45),
      ),
      // Already handled.
      Alerte(
        id: 4,
        patientId: 6,
        patientNom: 'Nadia Cherif',
        niveau: NiveauAlerte.moyen,
        message: 'Sommeil insuffisant depuis 3 jours.',
        date: jour(-5, 11, 5),
        traitee: true,
      ),
      Alerte(
        id: 5,
        patientId: 4,
        patientNom: 'Lina Mansouri',
        niveau: NiveauAlerte.faible,
        message: 'Douleur à 6/10 signalée deux jours de suite.',
        date: jour(-4, 8, 30),
        traitee: true,
      ),
    ];
  }

  // The patient with his alert level taken from his pending alerts
  // (the highest level, then the most recent).
  Patient _avecAlerte(Patient p) {
    final enCours =
        _alertes.where((a) => a.patientId == p.id && !a.traitee).toList();
    if (enCours.isEmpty) return p.avecAlerte(NiveauAlerte.aucune, null);

    enCours.sort((a, b) {
      final niveau = b.niveau.index.compareTo(a.niveau.index);
      return niveau != 0 ? niveau : b.date.compareTo(a.date);
    });
    return p.avecAlerte(enCours.first.niveau, enCours.first.message);
  }

  // All alerts, newest first.
  Future<List<Alerte>> getAlertes() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final liste = List.of(_alertes);
    liste.sort((a, b) => b.date.compareTo(a.date));
    return liste;
  }

  Future<void> marquerAlerteTraitee(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final i = _alertes.indexWhere((a) => a.id == id);
    if (i == -1) return;
    _alertes[i].traitee = true;
    alertesChanged.value++;
  }

  // One patient by id (with his alert level), null if unknown.
  Future<Patient?> getPatient(int id) async {
    final liste = await getPatients();
    for (final p in liste) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------- Profile photo (kept in memory for the session) ----------

  static Uint8List? _photo;
  static String? _photoEmail; // account the photo belongs to

  // The photo of this account, or null.
  Uint8List? getPhoto(AppUser user) => _photoEmail == user.email ? _photo : null;

  // Saves the photo (null removes it).
  void setPhoto(AppUser user, Uint8List? octets) {
    _photo = octets;
    _photoEmail = octets == null ? null : user.email;
  }

  // ---------- Agenda link ----------

  // Day of the next planned appointment (null if there is none).
  Future<DateTime?> prochainJourRdv() async {
    final maintenant = DateTime.now();
    final prochains = _rdvs
        .where((r) =>
            r.statut == StatutRdv.planifie && r.dateHeure.isAfter(maintenant))
        .toList()
      ..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
    return prochains.isEmpty ? null : prochains.first.dateHeure;
  }
}
import 'patient.dart';

// Everything the doctor's home page needs to display.
class HomeData {
  final String nomMedecin; // e.g. "Dr. Martin"
  final int patientsSuivis; // number of followed patients
  final int alertesAujourdhui; // number of alerts today
  final int rendezVousAVenir; // number of upcoming appointments
  final int ameliorationMoyenne; // in percent: 12 means +12%
  final List<Patient> patientsRecents; // recent patients list
  final DateTime? prochainRdv; // jour du prochain RDV planifié (null s'il n'y en a pas)

  const HomeData({
    required this.nomMedecin,
    required this.patientsSuivis,
    required this.alertesAujourdhui,
    required this.rendezVousAVenir,
    required this.ameliorationMoyenne,
    required this.patientsRecents,
    this.prochainRdv,
  });

  /// Réponse de GET /api/medecin/accueil (séance 6)
  factory HomeData.fromJson(Map<String, dynamic> j) => HomeData(
        nomMedecin: (j['nom_medecin'] as String?) ?? '',
        patientsSuivis: (j['patients_suivis'] as num?)?.toInt() ?? 0,
        alertesAujourdhui: (j['alertes_aujourdhui'] as num?)?.toInt() ?? 0,
        rendezVousAVenir: (j['rendez_vous_a_venir'] as num?)?.toInt() ?? 0,
        ameliorationMoyenne: (j['amelioration_moyenne'] as num?)?.toInt() ?? 0,
        patientsRecents: ((j['patients_recents'] as List?) ?? [])
            .map((p) => Patient.fromJson(p as Map<String, dynamic>))
            .toList(),
        prochainRdv: j['prochain_rdv'] == null
            ? null
            : DateTime.parse(j['prochain_rdv'] as String),
      );
}
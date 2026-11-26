import 'patient.dart'; // NiveauAlerte

// An alert raised for a patient (e.g. high pain in the daily follow-up).
class Alerte {
  final int id;
  final int patientId;
  final String patientNom;
  final NiveauAlerte niveau;
  final String message;
  final DateTime date;
  bool traitee; // true = the doctor marked it as handled

  Alerte({
    required this.id,
    required this.patientId,
    required this.patientNom,
    required this.niveau,
    required this.message,
    required this.date,
    this.traitee = false,
  });

  /// Réponse de GET /api/medecin/alertes (séance 6)
  factory Alerte.fromJson(Map<String, dynamic> j) => Alerte(
        id: (j['id'] as num).toInt(),
        patientId: (j['patient_id'] as num).toInt(),
        patientNom: (j['patient_nom'] as String?) ?? '',
        niveau: switch (j['niveau']) {
          'eleve' => NiveauAlerte.eleve,
          'moyen' => NiveauAlerte.moyen,
          _ => NiveauAlerte.faible,
        },
        message: (j['message'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
        traitee: j['traitee'] == true,
      );
}
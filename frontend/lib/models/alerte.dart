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
}
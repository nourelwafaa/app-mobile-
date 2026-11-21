import 'patient.dart';

// Result of a patient search by email or phone.
class ResultatRecherche {
  final Patient patient;
  final bool dejaSuivi; // true = already in the doctor's list

  const ResultatRecherche({required this.patient, required this.dejaSuivi});
}
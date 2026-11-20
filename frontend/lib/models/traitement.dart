// A medication prescribed to a patient.
class Traitement {
  final int id;
  final String nom; // e.g. "Plaquenil"
  final String dosage; // e.g. "200 mg"
  final int foisParJour;
  final DateTime debut;
  final DateTime? fin; // optional end date

  const Traitement({
    required this.id,
    required this.nom,
    required this.dosage,
    required this.foisParJour,
    required this.debut,
    this.fin,
  });

  // "Plaquenil 200 mg"
  String get libelle => '$nom $dosage';
}
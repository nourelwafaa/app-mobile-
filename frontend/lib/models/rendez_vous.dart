// Status of an appointment.
enum StatutRdv { planifie, termine, annule }

// One appointment of the doctor's agenda.
class RendezVous {
  final int id;
  final int patientId;
  final String patientNom;
  final DateTime dateHeure; // day + time
  final String motif; // reason
  final String? lieu; // place (optional)
  final StatutRdv statut;

  const RendezVous({
    required this.id,
    required this.patientId,
    required this.patientNom,
    required this.dateHeure,
    required this.motif,
    this.lieu,
    required this.statut,
  });

  // Same appointment with another status.
  RendezVous copyWith({StatutRdv? statut}) {
    return RendezVous(
      id: id,
      patientId: patientId,
      patientNom: patientNom,
      dateHeure: dateHeure,
      motif: motif,
      lieu: lieu,
      statut: statut ?? this.statut,
    );
  }
}
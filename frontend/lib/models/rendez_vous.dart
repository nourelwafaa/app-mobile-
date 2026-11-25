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

  /// Réponse de GET /api/medecin/rendez-vous ("date": "AAAA-MM-JJ", "heure": "HH:MM")
  factory RendezVous.fromJson(Map<String, dynamic> j) => RendezVous(
        id: (j['id'] as num).toInt(),
        patientId: (j['patient_id'] as num).toInt(),
        patientNom: (j['patient_nom'] as String?) ?? '',
        dateHeure: dateHeureDepuisJson(j),
        motif: (j['motif'] as String?) ?? '',
        lieu: j['lieu'] as String?,
        statut: StatutRdv.values.firstWhere(
          (s) => s.name == j['statut'],
          orElse: () => StatutRdv.planifie,
        ),
      );

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

/// "date": "2026-11-27" + "heure": "10:30" → DateTime (heure locale)
DateTime dateHeureDepuisJson(Map<String, dynamic> j) =>
    DateTime.parse('${j['date']}T${j['heure']}:00');

/// Rendez-vous vu par le patient (GET /api/patients/me/rendez-vous)
class RdvPatient {
  final int id;
  final DateTime dateHeure;
  final String motif;
  final String? lieu;
  final String? medecinNom;
  final String? medecinSpecialite;

  const RdvPatient({
    required this.id,
    required this.dateHeure,
    required this.motif,
    this.lieu,
    this.medecinNom,
    this.medecinSpecialite,
  });

  factory RdvPatient.fromJson(Map<String, dynamic> j) => RdvPatient(
        id: (j['id'] as num).toInt(),
        dateHeure: dateHeureDepuisJson(j),
        motif: (j['motif'] as String?) ?? '',
        lieu: j['lieu'] as String?,
        medecinNom: j['medecin_nom'] as String?,
        medecinSpecialite: j['medecin_specialite'] as String?,
      );

  /// "Dr Martin" (ajoute "Dr" si le nom ne le contient pas déjà)
  String? get docteur {
    final n = medecinNom?.trim();
    if (n == null || n.isEmpty) return null;
    final debut = n.toLowerCase();
    return debut.startsWith('dr ') || debut.startsWith('dr.') ? n : 'Dr $n';
  }
}

/// Analyse à venir vue par le patient (GET /api/patients/me/analyses)
class Analyse {
  final int id;
  final String type; // ex : "Bilan sanguin"
  final DateTime dateHeure;
  final String? laboratoire;

  const Analyse({
    required this.id,
    required this.type,
    required this.dateHeure,
    this.laboratoire,
  });

  factory Analyse.fromJson(Map<String, dynamic> j) => Analyse(
        id: (j['id'] as num).toInt(),
        type: (j['type_analyse'] as String?) ?? '',
        dateHeure: dateHeureDepuisJson(j),
        laboratoire: j['laboratoire'] as String?,
      );
}

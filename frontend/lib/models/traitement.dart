// A medication prescribed to a patient.
class Traitement {
  final int id;
  final String nom; // e.g. "Plaquenil"
  final String dosage; // e.g. "200 mg"
  final int foisParJour;
  final DateTime debut;
  final DateTime? fin; // optional end date
  final int? prescritPar; // id du médecin, null si ajouté par le patient
  final List<String> heures; // heures de rappel, ex : ["08:00", "20:00"]

  const Traitement({
    required this.id,
    required this.nom,
    required this.dosage,
    required this.foisParJour,
    required this.debut,
    this.fin,
    this.prescritPar,
    this.heures = const [],
  });

  // "Plaquenil 200 mg"
  String get libelle => '$nom $dosage';

  /// Réponse de GET /api/patients/me/traitements (dates "AAAA-MM-JJ")
  factory Traitement.fromJson(Map<String, dynamic> j) => Traitement(
        id: (j['id'] as num).toInt(),
        nom: j['nom'] as String,
        dosage: (j['dosage'] as String?) ?? '',
        foisParJour: (j['fois_par_jour'] as num).toInt(),
        debut: DateTime.parse(j['debut'] as String),
        fin: j['fin'] == null ? null : DateTime.parse(j['fin'] as String),
        prescritPar: (j['prescrit_par'] as num?)?.toInt(),
        heures: ((j['heures'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

/// Une prise prévue aujourd'hui (GET /api/patients/me/prises/aujourdhui)
class PriseDuJour {
  final int rappelId;
  final int traitementId;
  final String heure; // "08:00"
  final String nom;
  final String dosage;
  final bool pris;
  final String? heurePrise; // "08:12" si prise

  const PriseDuJour({
    required this.rappelId,
    required this.traitementId,
    required this.heure,
    required this.nom,
    required this.dosage,
    required this.pris,
    this.heurePrise,
  });

  factory PriseDuJour.fromJson(Map<String, dynamic> j) => PriseDuJour(
        rappelId: (j['rappel_id'] as num).toInt(),
        traitementId: (j['traitement_id'] as num).toInt(),
        heure: j['heure'] as String,
        nom: j['nom'] as String,
        dosage: (j['dosage'] as String?) ?? '',
        pris: j['pris'] == true,
        heurePrise: j['heure_prise'] as String?,
      );
}

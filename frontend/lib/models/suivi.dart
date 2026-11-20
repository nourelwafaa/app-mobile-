/// Suivi du jour (table suivi_quotidien + symptômes du jour)
class SuiviJour {
  final int douleur;
  final int fatigue;
  final int humeur;
  final double? sommeilHeures;
  final String? remarque;
  final List<String> symptomes;

  SuiviJour({
    required this.douleur,
    required this.fatigue,
    required this.humeur,
    this.sommeilHeures,
    this.remarque,
    this.symptomes = const [],
  });

  factory SuiviJour.fromJson(Map<String, dynamic> j) => SuiviJour(
        douleur: (j['douleur'] as num).toInt(),
        fatigue: (j['fatigue'] as num).toInt(),
        humeur: (j['humeur'] as num).toInt(),
        sommeilHeures: (j['sommeil_heures'] as num?)?.toDouble(),
        remarque: j['remarque'] as String?,
        symptomes: ((j['symptomes'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'douleur': douleur,
        'fatigue': fatigue,
        'humeur': humeur,
        'sommeil_heures': sommeilHeures,
        'remarque': remarque,
        'symptomes': symptomes,
      };
}

/// Un jour de la période (valeurs null si pas de suivi ce jour-là)
class StatsJour {
  final DateTime date;
  final int? douleur;
  final int? fatigue;
  final int? humeur;
  final double? sommeilHeures;

  StatsJour({
    required this.date,
    this.douleur,
    this.fatigue,
    this.humeur,
    this.sommeilHeures,
  });

  factory StatsJour.fromJson(Map<String, dynamic> j) => StatsJour(
        date: DateTime.parse(j['date'] as String),
        douleur: (j['douleur'] as num?)?.toInt(),
        fatigue: (j['fatigue'] as num?)?.toInt(),
        humeur: (j['humeur'] as num?)?.toInt(),
        sommeilHeures: (j['sommeil_heures'] as num?)?.toDouble(),
      );
}

/// Réponse de GET /api/patients/me/stats
class Stats {
  final int periode;
  final List<StatsJour> jours;
  final double? moyDouleur;
  final double? moyFatigue;
  final double? moySommeil;
  final int joursRemplis;
  final String? symptomeNom;
  final int? symptomeJours;
  final String? evolutionFatigue; // baisse | hausse | stable | null

  Stats({
    required this.periode,
    required this.jours,
    required this.joursRemplis,
    this.moyDouleur,
    this.moyFatigue,
    this.moySommeil,
    this.symptomeNom,
    this.symptomeJours,
    this.evolutionFatigue,
  });

  factory Stats.fromJson(Map<String, dynamic> j) {
    final m = (j['moyennes'] as Map<String, dynamic>?) ?? {};
    final s = j['symptome_frequent'] as Map<String, dynamic>?;
    final t = j['tendance_fatigue'] as Map<String, dynamic>?;
    return Stats(
      periode: (j['periode'] as num).toInt(),
      jours: ((j['jours'] as List?) ?? [])
          .map((e) => StatsJour.fromJson(e as Map<String, dynamic>))
          .toList(),
      moyDouleur: (m['douleur'] as num?)?.toDouble(),
      moyFatigue: (m['fatigue'] as num?)?.toDouble(),
      moySommeil: (m['sommeil_heures'] as num?)?.toDouble(),
      joursRemplis: (m['jours_remplis'] as num?)?.toInt() ?? 0,
      symptomeNom: s?['nom'] as String?,
      symptomeJours: (s?['jours'] as num?)?.toInt(),
      evolutionFatigue: t?['evolution'] as String?,
    );
  }
}

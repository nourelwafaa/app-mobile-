/// Demande d'un médecin pour suivre le patient (consentement).
/// GET /api/patients/me/demandes
class DemandeSuivi {
  final int id;
  final int medecinId;
  final String medecinNom;
  final String? specialite;
  final String? etablissement;

  const DemandeSuivi({
    required this.id,
    required this.medecinId,
    required this.medecinNom,
    this.specialite,
    this.etablissement,
  });

  factory DemandeSuivi.fromJson(Map<String, dynamic> j) => DemandeSuivi(
        id: (j['id'] as num).toInt(),
        medecinId: (j['medecin_id'] as num).toInt(),
        medecinNom: (j['medecin_nom'] as String?) ?? '',
        specialite: j['medecin_specialite'] as String?,
        etablissement: j['medecin_etablissement'] as String?,
      );

  /// "Dr Karim Martin" (ajoute "Dr" si le nom ne le contient pas déjà)
  String get docteur {
    final n = medecinNom.trim();
    final debut = n.toLowerCase();
    return debut.startsWith('dr ') || debut.startsWith('dr.') ? n : 'Dr $n';
  }
}

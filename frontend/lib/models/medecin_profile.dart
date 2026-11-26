// The doctor's profile.
// Fields marked "?" can be empty: right after sign-up, the backend
// creates the professional profile with everything empty.
class MedecinProfile {
  final String nomComplet; // e.g. "Martin" (the app adds "Dr " when displaying)
  final String? specialite;
  final String? etablissement;
  final String? adresse;
  final String? ville;
  final String email; // always present (it is the login)
  final String? telephone;

  const MedecinProfile({
    required this.nomComplet,
    this.specialite,
    this.etablissement,
    this.adresse,
    this.ville,
    required this.email,
    this.telephone,
  });

  // "12 rue X, Alger" built from address + city.
  // Returns null if both are empty, so the screen can show "Non renseigné".
  /// Réponse de GET /api/medecin/profil (séance 6)
  factory MedecinProfile.fromJson(Map<String, dynamic> j) => MedecinProfile(
        nomComplet: (j['nom_complet'] as String?) ?? '',
        specialite: j['specialite'] as String?,
        etablissement: j['etablissement'] as String?,
        adresse: j['adresse'] as String?,
        ville: j['ville'] as String?,
        email: (j['email'] as String?) ?? '',
        telephone: j['telephone'] as String?,
      );

  /// Corps de PUT /api/medecin/profil (l'email ne change pas)
  Map<String, dynamic> toJson() => {
        'nom_complet': nomComplet,
        'specialite': specialite,
        'etablissement': etablissement,
        'adresse': adresse,
        'ville': ville,
        'telephone': telephone,
      };

  String? get adresseComplete {
    final parts = [adresse, ville]
        .where((p) => p != null && p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}
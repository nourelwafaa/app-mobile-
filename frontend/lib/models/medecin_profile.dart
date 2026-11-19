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
  String? get adresseComplete {
    final parts = [adresse, ville]
        .where((p) => p != null && p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}
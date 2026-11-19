class AppUser {
  final int id;
  final String nomComplet;
  final String email;
  final String? telephone;
  final String? dateNaissance; // "2000-05-15"
  final String role; // patient | medecin
  final String? photo;

  AppUser({
    required this.id,
    required this.nomComplet,
    required this.email,
    required this.role,
    this.telephone,
    this.dateNaissance,
    this.photo,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        nomComplet: j['nom_complet'] as String,
        email: j['email'] as String,
        telephone: j['telephone'] as String?,
        dateNaissance: j['date_naissance'] as String?,
        role: j['role'] as String,
        photo: j['photo'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom_complet': nomComplet,
        'email': email,
        'telephone': telephone,
        'date_naissance': dateNaissance,
        'role': role,
        'photo': photo,
      };

  String get prenom => nomComplet.trim().split(' ').first;
}

/// Réponse de GET /api/patients/me
class PatientProfile {
  final AppUser user;
  final int? age;
  final String? sexe; // homme | femme
  final double? poids;
  final double? taille;
  final String? groupeSanguin;

  PatientProfile({
    required this.user,
    this.age,
    this.sexe,
    this.poids,
    this.taille,
    this.groupeSanguin,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> j) => PatientProfile(
        user: AppUser.fromJson(j),
        age: (j['age'] as num?)?.toInt(),
        sexe: j['sexe'] as String?,
        poids: (j['poids'] as num?)?.toDouble(),
        taille: (j['taille'] as num?)?.toDouble(),
        groupeSanguin: j['groupe_sanguin'] as String?,
      );
}

/// Données de l'écran "Créer un compte", envoyées après le choix du type de compte
class RegisterDraft {
  final String nomComplet;
  final String email;
  final String? telephone;
  final String motDePasse;
  final String? dateNaissance; // "AAAA-MM-JJ"

  RegisterDraft({
    required this.nomComplet,
    required this.email,
    required this.motDePasse,
    this.telephone,
    this.dateNaissance,
  });
}

// Alert level of a patient.
enum NiveauAlerte { aucune, faible, moyen, eleve }

// A patient followed by the doctor.
class Patient {
  final int id;
  final String nom; // full name
  final DateTime derniereActivite; // date and time of the last follow-up
  final DateTime? dateNaissance;
  final String? sexe; // "Femme" or "Homme"
  final String? groupeSanguin; // e.g. "AB+"
  final NiveauAlerte alerte;
  final String? messageAlerte; // e.g. "Douleur 8/10 signalée aujourd'hui"
  final List<int> douleur7Jours; // pain 0-10 of the last 7 days, today last
  final bool rdvCetteSemaine; // un RDV non annulé cette semaine (filtre « RDV »)

  const Patient({
    required this.id,
    required this.nom,
    required this.derniereActivite,
    this.dateNaissance,
    this.sexe,
    this.groupeSanguin,
    this.alerte = NiveauAlerte.aucune,
    this.messageAlerte,
    this.douleur7Jours = const [],
    this.rdvCetteSemaine = false,
  });

  /// Réponse de GET /api/medecin/patients (séance 6)
  factory Patient.fromJson(Map<String, dynamic> j) {
    final sexe = j['sexe'] as String?;
    return Patient(
      id: (j['id'] as num).toInt(),
      nom: (j['nom'] as String?) ?? '',
      derniereActivite: j['derniere_activite'] == null
          ? DateTime.now()
          : DateTime.parse(j['derniere_activite'] as String),
      dateNaissance: j['date_naissance'] == null
          ? null
          : DateTime.parse(j['date_naissance'] as String),
      // "femme" → "Femme" (format attendu par les écrans)
      sexe: sexe == null || sexe.isEmpty
          ? null
          : sexe[0].toUpperCase() + sexe.substring(1),
      groupeSanguin: j['groupe_sanguin'] as String?,
      alerte: switch (j['alerte_niveau']) {
        'eleve' => NiveauAlerte.eleve,
        'moyen' => NiveauAlerte.moyen,
        'faible' => NiveauAlerte.faible,
        _ => NiveauAlerte.aucune,
      },
      messageAlerte: j['alerte_message'] as String?,
      douleur7Jours: _douleurs(j['douleur_7_jours'] as List?),
      rdvCetteSemaine: j['rdv_cette_semaine'] == true,
    );
  }

  // Aucun suivi sur 7 jours → liste vide (le graphique affiche « pas de données »).
  // Sinon, un jour sans suivi compte comme 0.
  static List<int> _douleurs(List? valeurs) {
    if (valeurs == null || valeurs.every((v) => v == null)) return const [];
    return valeurs.map((v) => (v as num?)?.toInt() ?? 0).toList();
  }

  // First letter of the name, shown in the colored circle.
  String get initiale => nom[0].toUpperCase();

  // Same patient with another alert level and message.
  Patient avecAlerte(NiveauAlerte niveau, String? message) {
    return Patient(
      id: id,
      nom: nom,
      derniereActivite: derniereActivite,
      dateNaissance: dateNaissance,
      sexe: sexe,
      groupeSanguin: groupeSanguin,
      alerte: niveau,
      messageAlerte: message,
      douleur7Jours: douleur7Jours,
      rdvCetteSemaine: rdvCetteSemaine,
    );
  }

  // Age in years, computed from the birth date (null if unknown).
  int? get age {
    final d = dateNaissance;
    if (d == null) return null;
    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return age;
  }
}
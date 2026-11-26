// Type of a medical document.
enum TypeDocument { ordonnance, analyse, compteRendu, imagerie }

extension TypeDocumentTexte on TypeDocument {
  // Singular: shown on each row ("Ordonnance · 2 nov. 2026").
  String get label => switch (this) {
        TypeDocument.ordonnance => 'Ordonnance',
        TypeDocument.analyse => 'Analyse',
        TypeDocument.compteRendu => 'Compte rendu',
        TypeDocument.imagerie => 'Imagerie',
      };

  // Plural: shown on the filter chips.
  String get labelPluriel => switch (this) {
        TypeDocument.ordonnance => 'Ordonnances',
        TypeDocument.analyse => 'Analyses',
        TypeDocument.compteRendu => 'Comptes rendus',
        TypeDocument.imagerie => 'Imagerie',
      };
}

// A medical document of a patient (no real file for now).
class DocumentMedical {
  final int id;
  final String titre;
  final TypeDocument type;
  final DateTime date;

  const DocumentMedical({
    required this.id,
    required this.titre,
    required this.type,
    required this.date,
  });

  /// Réponse de GET /api/.../documents ("date_document": "AAAA-MM-JJ")
  factory DocumentMedical.fromJson(Map<String, dynamic> j) => DocumentMedical(
        id: (j['id'] as num).toInt(),
        titre: (j['titre'] as String?) ?? '',
        type: typeDepuisApi(j['type_document'] as String?),
        date: DateTime.parse(j['date_document'] as String),
      );
}

/// Valeur de la base → type de l'app ("compte_rendu" → compteRendu).
/// "autre" n'existe pas dans l'app : affiché comme un compte rendu.
TypeDocument typeDepuisApi(String? v) => switch (v) {
      'ordonnance' => TypeDocument.ordonnance,
      'analyse' => TypeDocument.analyse,
      'imagerie' => TypeDocument.imagerie,
      _ => TypeDocument.compteRendu,
    };

/// Type de l'app → valeur attendue par l'API (compteRendu → "compte_rendu").
String typeVersApi(TypeDocument t) => switch (t) {
      TypeDocument.ordonnance => 'ordonnance',
      TypeDocument.analyse => 'analyse',
      TypeDocument.compteRendu => 'compte_rendu',
      TypeDocument.imagerie => 'imagerie',
    };

/// Médecin qui a accès au dossier (GET /api/patients/me/partages)
class PartageDossier {
  final int medecinId;
  final String medecinNom;
  final String? specialite;

  const PartageDossier({
    required this.medecinId,
    required this.medecinNom,
    this.specialite,
  });

  factory PartageDossier.fromJson(Map<String, dynamic> j) => PartageDossier(
        medecinId: (j['medecin_id'] as num).toInt(),
        medecinNom: (j['medecin_nom'] as String?) ?? '',
        specialite: j['medecin_specialite'] as String?,
      );

  /// "Dr Karim Martin" (ajoute "Dr" si le nom ne le contient pas déjà)
  String get docteur {
    final n = medecinNom.trim();
    final debut = n.toLowerCase();
    return debut.startsWith('dr ') || debut.startsWith('dr.') ? n : 'Dr $n';
  }
}
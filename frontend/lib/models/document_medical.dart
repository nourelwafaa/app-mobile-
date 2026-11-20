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
}
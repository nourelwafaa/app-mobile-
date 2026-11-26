// One message of a conversation.
class Message {
  final int id;
  final bool deMoi; // true = envoyé par la personne connectée (médecin ou patient)
  final String texte;
  final DateTime date;
  bool lu; // false = patient message not read yet by the doctor

  Message({
    required this.id,
    required this.deMoi,
    required this.texte,
    required this.date,
    required this.lu,
  });

  /// Réponse de l'API messagerie (séance 7) : "texte", "de_moi", "date", "lu"
  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: (j['id'] as num).toInt(),
        deMoi: j['de_moi'] == true,
        texte: (j['texte'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
        lu: j['lu'] == true,
      );
}

/// Un médecin qui suit le patient, vu dans « Messages » côté patient
/// (GET /api/patients/me/medecins).
class MonMedecin {
  final int id;
  final String nom; // "Karim Martin"
  final String? specialite;
  final Message? dernierMessage; // null = pas encore de message
  final int nonLus; // messages du médecin pas encore lus par le patient

  const MonMedecin({
    required this.id,
    required this.nom,
    this.specialite,
    this.dernierMessage,
    this.nonLus = 0,
  });

  factory MonMedecin.fromJson(Map<String, dynamic> j) => MonMedecin(
        id: (j['medecin_id'] as num).toInt(),
        nom: (j['medecin_nom'] as String?) ?? '',
        specialite: j['medecin_specialite'] as String?,
        dernierMessage: j['dernier_message'] == null
            ? null
            : Message.fromJson(j['dernier_message'] as Map<String, dynamic>),
        nonLus: (j['non_lus'] as num?)?.toInt() ?? 0,
      );

  /// "Dr Karim Martin" (ajoute "Dr" si le nom ne le contient pas déjà)
  String get docteur {
    final n = nom.trim();
    final debut = n.toLowerCase();
    return debut.startsWith('dr ') || debut.startsWith('dr.') ? n : 'Dr $n';
  }

  /// Lettre du cercle (nom de famille, comme « M » pour Dr Martin)
  String get initiale {
    final mots = nom.trim().split(RegExp(r'\s+'));
    final dernier = mots.isEmpty ? '' : mots.last;
    return dernier.isEmpty ? '?' : dernier[0].toUpperCase();
  }
}
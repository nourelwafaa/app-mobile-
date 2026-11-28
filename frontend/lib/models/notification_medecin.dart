import 'patient.dart'; // NiveauAlerte

// What the notification is about.
enum TypeNotification { message, alerte, rendezVous }

// One notification of the doctor (named so it doesn't clash with Flutter's own class).
class NotificationMedecin {
  final int id;
  final TypeNotification type;
  final String titre;
  final String description;
  final DateTime date;
  final int? patientId; // for a message: the patient to open
  final NiveauAlerte niveau; // for an alert: color of the icon
  final DateTime? rdvDate; // for an appointment: the day to show in the Agenda
  bool lu;

  NotificationMedecin({
    required this.id,
    required this.type,
    required this.titre,
    required this.description,
    required this.date,
    this.patientId,
    this.niveau = NiveauAlerte.aucune,
    this.rdvDate,
    this.lu = false,
  });

  /// Une ligne de GET /api/medecin/notifications (séance 8)
  factory NotificationMedecin.fromJson(Map<String, dynamic> j) =>
      NotificationMedecin(
        id: (j['id'] as num).toInt(),
        type: switch (j['type']) {
          'message' => TypeNotification.message,
          'alerte' => TypeNotification.alerte,
          _ => TypeNotification.rendezVous,
        },
        titre: (j['titre'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
        patientId: (j['patient_id'] as num?)?.toInt(),
        niveau: switch (j['niveau']) {
          'eleve' => NiveauAlerte.eleve,
          'moyen' => NiveauAlerte.moyen,
          'faible' => NiveauAlerte.faible,
          _ => NiveauAlerte.aucune,
        },
        rdvDate: j['rdv_date'] == null
            ? null
            : DateTime.parse(j['rdv_date'] as String),
        lu: j['lu'] == true,
      );
}
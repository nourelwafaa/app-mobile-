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
}
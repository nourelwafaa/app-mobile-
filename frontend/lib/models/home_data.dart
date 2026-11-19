import 'patient.dart';

// Everything the doctor's home page needs to display.
class HomeData {
  final String nomMedecin; // e.g. "Dr. Martin"
  final int patientsSuivis; // number of followed patients
  final int alertesAujourdhui; // number of alerts today
  final int rendezVousAVenir; // number of upcoming appointments
  final int ameliorationMoyenne; // in percent: 12 means +12%
  final List<Patient> patientsRecents; // recent patients list

  const HomeData({
    required this.nomMedecin,
    required this.patientsSuivis,
    required this.alertesAujourdhui,
    required this.rendezVousAVenir,
    required this.ameliorationMoyenne,
    required this.patientsRecents,
  });
}
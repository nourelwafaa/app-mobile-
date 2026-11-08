import '../models/home_data.dart';
import '../models/patient.dart';

// Gives the data to the screens.
// For now the data is FAKE. When the backend is ready, only the inside of
// this method changes (it will call the API); the screens stay the same.
class MedecinService {
  Future<HomeData> getHomeData() async {
    // Waits half a second to imitate a real network call.
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();

    return HomeData(
      nomMedecin: 'Dr. Martin',
      patientsSuivis: 24,
      alertesAujourdhui: 3,
      rendezVousAVenir: 5,
      ameliorationMoyenne: 12,
      patientsRecents: [
        // Today at 09:12
        Patient(
          id: 1,
          nom: 'Sarah Benali',
          derniereActivite: DateTime(now.year, now.month, now.day, 9, 12),
        ),
        // Yesterday at 16:45
        Patient(
          id: 2,
          nom: 'Maya Dubois',
          derniereActivite: DateTime(now.year, now.month, now.day - 1, 16, 45),
        ),
        // Yesterday at 14:20
        Patient(
          id: 3,
          nom: 'Amira Haddad',
          derniereActivite: DateTime(now.year, now.month, now.day - 1, 14, 20),
        ),
      ],
    );
  }
}
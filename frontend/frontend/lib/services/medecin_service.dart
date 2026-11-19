import '../models/home_data.dart';
import '../models/medecin_profile.dart';
import '../models/models.dart'; // AppUser (the logged-in account)
import '../models/patient.dart';

// Gives the data to the screens.
// For now the data is FAKE. When the backend is ready, only the inside of
// these methods changes (they will call the API); the screens stay the same.
class MedecinService {
  // The doctor's profile, kept in memory for the whole app session.
  // "static" = one single copy shared by the whole app.
  static MedecinProfile? _profile;

  // Email of the account this profile belongs to.
  static String? _profileEmail;

  // Returns the stored profile, or builds a new one from the logged-in account.
  // Like the real backend after sign-up: only name, email and phone are known,
  // the other fields start empty ("Non renseigné").
  MedecinProfile _profileFor(AppUser user) {
    // First call, or a DIFFERENT account logged in: start from scratch.
    if (_profile == null || _profileEmail != user.email) {
      _profile = MedecinProfile(
        nomComplet: user.nomComplet,
        email: user.email,
        telephone: user.telephone,
      );
      _profileEmail = user.email;
    }
    return _profile!;
  }

  // Data of the home page.
  Future<HomeData> getHomeData(AppUser user) async {
    // Waits half a second to imitate a real network call.
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();

    return HomeData(
      // The name comes from the profile, so an edit is also seen here.
      nomMedecin: _profileFor(user).nomComplet,
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

  // Data of the profile page.
  Future<MedecinProfile> getProfile(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _profileFor(user);
  }

  // Saves the edited profile.
  // Memory only for now; later it will call the backend.
  Future<void> updateProfile(MedecinProfile newProfile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profile = newProfile;
    _profileEmail = newProfile.email; // the email is never changed by an edit
  }
}
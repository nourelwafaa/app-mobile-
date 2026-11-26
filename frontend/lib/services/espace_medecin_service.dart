import '../core/api_client.dart';
import '../models/alerte.dart';
import '../models/home_data.dart';
import '../models/medecin_profile.dart';
import '../models/patient.dart';
import '../models/resultat_recherche.dart';

/// Appels au backend pour l'espace médecin (séance 6) : ses patients.
/// Remplace les fausses données de medecin_service.dart.
/// Utilise l'ApiClient de AuthProvider (il contient déjà le token).
class EspaceMedecinService {
  final ApiClient api;
  EspaceMedecinService(this.api);

  /// GET /api/medecin/patients (alerte en cours, douleur 7 jours, RDV cette semaine)
  Future<List<Patient>> getPatients() async {
    final data = await api.get('/medecin/patients');
    return ((data['patients'] as List?) ?? [])
        .map((p) => Patient.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/medecin/patients/:id → null si ce n'est pas un patient du médecin
  Future<Patient?> getPatient(int id) async {
    try {
      final data = await api.get('/medecin/patients/$id');
      return Patient.fromJson(data['patient'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// GET /api/medecin/patients/recherche?identifiant=... → null si personne
  Future<ResultatRecherche?> rechercherPatient(String identifiant) async {
    try {
      final q = Uri.encodeQueryComponent(identifiant.trim());
      final data = await api.get('/medecin/patients/recherche?identifiant=$q');
      return ResultatRecherche(
        patient: Patient.fromJson(data['patient'] as Map<String, dynamic>),
        dejaSuivi: data['deja_suivi'] == true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /api/medecin/patients (crée aussi l'accès au dossier)
  Future<void> ajouterPatient(int patientId) async {
    await api.post('/medecin/patients', {'patient_id': patientId});
  }

  // ---------- Alertes ----------

  /// GET /api/medecin/alertes (à traiter + traitées, plus récentes d'abord)
  Future<List<Alerte>> getAlertes() async {
    final data = await api.get('/medecin/alertes');
    return ((data['alertes'] as List?) ?? [])
        .map((a) => Alerte.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  /// PUT /api/medecin/alertes/:id/traitee
  Future<void> traiterAlerte(int id) async {
    await api.put('/medecin/alertes/$id/traitee', {});
  }

  // ---------- Accueil + profil ----------

  /// GET /api/medecin/accueil (compteurs, 3 patients récents, prochain RDV)
  Future<HomeData> getAccueil() async =>
      HomeData.fromJson(await api.get('/medecin/accueil'));

  /// GET /api/medecin/profil
  Future<MedecinProfile> getProfil() async {
    final data = await api.get('/medecin/profil');
    return MedecinProfile.fromJson(data['profil'] as Map<String, dynamic>);
  }

  /// PUT /api/medecin/profil
  Future<void> majProfil(MedecinProfile profil) async {
    await api.put('/medecin/profil', profil.toJson());
  }
}

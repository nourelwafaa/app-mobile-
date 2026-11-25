import '../core/api_client.dart';
import '../models/patient.dart';
import '../models/rendez_vous.dart';

/// Appels au backend pour les rendez-vous et les analyses (séance 4).
/// Le médecin crée ; le patient consulte.
/// Utilise l'ApiClient de AuthProvider (il contient déjà le token).
class AgendaService {
  final ApiClient api;
  AgendaService(this.api);

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _heure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // ---------- Patient ----------

  /// GET /api/patients/me/rendez-vous (à venir, du plus proche au plus lointain)
  Future<List<RdvPatient>> getMesRendezVous() async {
    final data = await api.get('/patients/me/rendez-vous');
    return ((data['rendez_vous'] as List?) ?? [])
        .map((r) => RdvPatient.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/patients/me/analyses (à venir)
  Future<List<Analyse>> getMesAnalyses() async {
    final data = await api.get('/patients/me/analyses');
    return ((data['analyses'] as List?) ?? [])
        .map((a) => Analyse.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  // ---------- Médecin ----------

  /// GET /api/medecin/patients (patients suivis)
  Future<List<Patient>> getPatients() async {
    final data = await api.get('/medecin/patients');
    return ((data['patients'] as List?) ?? [])
        .map((p) => Patient.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/medecin/rendez-vous (agenda du médecin)
  Future<List<RendezVous>> getRendezVous() async {
    final data = await api.get('/medecin/rendez-vous');
    return ((data['rendez_vous'] as List?) ?? [])
        .map((r) => RendezVous.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/medecin/rendez-vous
  Future<void> ajouterRendezVous({
    required int patientId,
    required DateTime dateHeure,
    required String motif,
    String? lieu,
  }) async {
    await api.post('/medecin/rendez-vous', {
      'patient_id': patientId,
      'date': _date(dateHeure),
      'heure': _heure(dateHeure),
      'motif': motif,
      'lieu': lieu,
    });
  }

  /// PUT /api/medecin/rendez-vous/:id/statut (termine | annule)
  Future<void> changerStatut(int id, StatutRdv statut) async {
    await api.put('/medecin/rendez-vous/$id/statut', {'statut': statut.name});
  }
}

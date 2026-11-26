import '../core/api_client.dart';
import '../models/traitement.dart';

/// Appels au backend pour les traitements et les prises du patient connecté.
/// Utilise l'ApiClient de AuthProvider (il contient déjà le token).
class TraitementService {
  final ApiClient api;
  TraitementService(this.api);

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// GET /api/patients/me/traitements
  Future<List<Traitement>> getMesTraitements() async {
    final data = await api.get('/patients/me/traitements');
    return ((data['traitements'] as List?) ?? [])
        .map((t) => Traitement.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/patients/me/traitements (heures de rappel calculées par le serveur)
  Future<Traitement> ajouter({
    required String nom,
    required String dosage,
    required int foisParJour,
    required DateTime debut,
    DateTime? fin,
  }) async {
    final data = await api.post('/patients/me/traitements', {
      'nom': nom,
      'dosage': dosage,
      'fois_par_jour': foisParJour,
      'debut': _date(debut),
      'fin': fin == null ? null : _date(fin),
    });
    return Traitement.fromJson(data['traitement'] as Map<String, dynamic>);
  }

  /// GET /api/patients/me/prises/aujourdhui (triées par heure)
  Future<List<PriseDuJour>> getPrisesDuJour() async {
    final data = await api.get('/patients/me/prises/aujourdhui');
    return ((data['prises'] as List?) ?? [])
        .map((p) => PriseDuJour.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  // ---------- Médecin (API de la séance 3, branchées en séance 6) ----------

  /// GET /api/medecin/patients/:patientId/traitements
  Future<List<Traitement>> getTraitementsPatient(int patientId) async {
    final data = await api.get('/medecin/patients/$patientId/traitements');
    return ((data['traitements'] as List?) ?? [])
        .map((t) => Traitement.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/medecin/patients/:patientId/traitements (le médecin prescrit)
  Future<void> prescrire({
    required int patientId,
    required String nom,
    required String dosage,
    required int foisParJour,
    required DateTime debut,
    DateTime? fin,
  }) async {
    await api.post('/medecin/patients/$patientId/traitements', {
      'nom': nom,
      'dosage': dosage,
      'fois_par_jour': foisParJour,
      'debut': _date(debut),
      'fin': fin == null ? null : _date(fin),
    });
  }

  /// POST /api/patients/me/prises : bouton « Marquer pris »
  Future<void> marquerPrise(int rappelId) async {
    await api.post('/patients/me/prises', {'rappel_id': rappelId});
  }
}

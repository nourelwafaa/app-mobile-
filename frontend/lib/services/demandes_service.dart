import '../core/api_client.dart';
import '../models/demande_suivi.dart';

/// Consentement du patient : demandes de suivi des médecins.
/// Utilise l'ApiClient de AuthProvider (il contient déjà le token).
class DemandesService {
  final ApiClient api;
  DemandesService(this.api);

  /// GET /api/patients/me/demandes (en attente)
  Future<List<DemandeSuivi>> getDemandes() async {
    final data = await api.get('/patients/me/demandes');
    return ((data['demandes'] as List?) ?? [])
        .map((d) => DemandeSuivi.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  /// PUT /api/patients/me/demandes/:id → renvoie le message du serveur
  Future<String> repondre(int id, {required bool accepter}) async {
    final data = await api.put('/patients/me/demandes/$id', {
      'decision': accepter ? 'accepter' : 'refuser',
    });
    return (data['message'] as String?) ?? '';
  }
}

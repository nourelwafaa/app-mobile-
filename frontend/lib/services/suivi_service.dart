import '../core/api_client.dart';
import '../models/suivi.dart';

/// Appels au backend pour le suivi du jour et les statistiques.
/// Utilise l'ApiClient de AuthProvider (il contient déjà le token).
class SuiviService {
  final ApiClient api;
  SuiviService(this.api);

  /// GET /api/patients/me/suivi/aujourdhui  → null si pas encore fait aujourd'hui
  Future<SuiviJour?> getAujourdhui() async {
    final data = await api.get('/patients/me/suivi/aujourdhui');
    final s = data['suivi'];
    return s == null ? null : SuiviJour.fromJson(s as Map<String, dynamic>);
  }

  /// POST /api/patients/me/suivi  (remplace le suivi du jour s'il existe déjà)
  Future<void> enregistrer(SuiviJour suivi) async {
    await api.post('/patients/me/suivi', suivi.toJson());
  }

  /// GET /api/patients/me/stats?periode=7 | 30 | 90
  Future<Stats> getStats(int periode) async {
    final data = await api.get('/patients/me/stats?periode=$periode');
    return Stats.fromJson(data);
  }
}

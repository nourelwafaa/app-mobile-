import '../core/api_client.dart';
import '../models/document_medical.dart';

/// Appels au backend pour le dossier médical (séance 5).
/// Le médecin ajoute les documents ; le patient les consulte.
/// Utilise l'ApiClient de AuthProvider (il contient déjà le token).
class DossierService {
  final ApiClient api;
  DossierService(this.api);

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static List<DocumentMedical> _documents(Map<String, dynamic> data) =>
      ((data['documents'] as List?) ?? [])
          .map((d) => DocumentMedical.fromJson(d as Map<String, dynamic>))
          .toList();

  // ---------- Patient ----------

  /// GET /api/patients/me/documents (du plus récent au plus ancien)
  Future<List<DocumentMedical>> getMesDocuments() async =>
      _documents(await api.get('/patients/me/documents'));

  /// GET /api/patients/me/partages (section « Partagé avec »)
  Future<List<PartageDossier>> getMesPartages() async {
    final data = await api.get('/patients/me/partages');
    return ((data['partages'] as List?) ?? [])
        .map((p) => PartageDossier.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  // ---------- Médecin ----------

  /// GET /api/medecin/patients/:patientId/documents
  Future<List<DocumentMedical>> getDocumentsPatient(int patientId) async =>
      _documents(await api.get('/medecin/patients/$patientId/documents'));

  /// POST /api/medecin/patients/:patientId/documents
  Future<void> ajouterDocument({
    required int patientId,
    required String titre,
    required TypeDocument type,
    required DateTime date,
  }) async {
    await api.post('/medecin/patients/$patientId/documents', {
      'titre': titre,
      'type_document': typeVersApi(type),
      'date_document': _date(date),
    });
  }
}

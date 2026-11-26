import '../core/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';

/// Appels au backend pour la messagerie (séance 7).
/// Uniquement entre un médecin et un patient qu'il suit.
/// Utilise l'ApiClient de AuthProvider (il contient déjà le token).
class MessagesService {
  final ApiClient api;
  MessagesService(this.api);

  static List<Message> _messages(Map<String, dynamic> data) =>
      ((data['messages'] as List?) ?? [])
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList();

  // ---------- Patient ----------

  /// GET /api/patients/me/medecins (dernier message + non-lus)
  Future<List<MonMedecin>> getMesMedecins() async {
    final data = await api.get('/patients/me/medecins');
    return ((data['medecins'] as List?) ?? [])
        .map((m) => MonMedecin.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Total des messages non lus (point rouge de l'accueil patient)
  Future<int> nombreNonLusPatient() async {
    final medecins = await getMesMedecins();
    return medecins.fold<int>(0, (total, m) => total + m.nonLus);
  }

  /// GET /api/patients/me/messages/:medecinId (les messages reçus passent en « lu »)
  Future<List<Message>> getMessagesMedecin(int medecinId) async =>
      _messages(await api.get('/patients/me/messages/$medecinId'));

  /// POST /api/patients/me/messages/:medecinId
  Future<void> ecrireAuMedecin(int medecinId, String texte) async {
    await api.post('/patients/me/messages/$medecinId', {'texte': texte});
  }

  // ---------- Médecin ----------

  /// GET /api/medecin/conversations (plus récente d'abord)
  Future<List<Conversation>> getConversations() async {
    final data = await api.get('/medecin/conversations');
    return ((data['conversations'] as List?) ?? [])
        .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/medecin/messages/:patientId (les messages reçus passent en « lu »)
  Future<List<Message>> getMessagesPatient(int patientId) async =>
      _messages(await api.get('/medecin/messages/$patientId'));

  /// POST /api/medecin/messages/:patientId
  Future<void> ecrireAuPatient(int patientId, String texte) async {
    await api.post('/medecin/messages/$patientId', {'texte': texte});
  }
}

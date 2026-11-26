import 'message.dart';
import 'patient.dart';

// One line of the conversations list.
class Conversation {
  final Patient patient;
  final Message dernierMessage;
  final int nonLus; // number of unread messages from the patient

  const Conversation({
    required this.patient,
    required this.dernierMessage,
    required this.nonLus,
  });

  /// Réponse de GET /api/medecin/conversations (séance 7)
  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        patient: Patient.fromJson(j['patient'] as Map<String, dynamic>),
        dernierMessage:
            Message.fromJson(j['dernier_message'] as Map<String, dynamic>),
        nonLus: (j['non_lus'] as num?)?.toInt() ?? 0,
      );
}
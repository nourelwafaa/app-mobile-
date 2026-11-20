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
}
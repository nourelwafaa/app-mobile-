import 'package:flutter/material.dart';
import '../../widgets/chat_view.dart';

/// Assistant LupIA. Ici les réponses sont simulées.
/// TODO : brancher sur ton backend (qui appellera l'IA) via une route type
/// POST /api/lupia/message { message } -> { reponse }.
class LupiaScreen extends StatelessWidget {
  const LupiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatView(
      title: 'LupIA',
      subtitle: 'En ligne',
      initial: [
        ChatMessage(
            "Bonjour, je suis LupIA, votre assistante. Comment vous sentez-vous aujourd'hui ?",
            false,
            '09:00'),
      ],
      quickReplies: const ['Rappel médicament', 'Suivre mes symptômes'],
      onSend: (msg) async {
        await Future.delayed(const Duration(milliseconds: 900));
        return "Merci pour votre message. Je vous conseille de noter ce symptôme dans votre suivi du jour et d'en parler à votre médecin si cela persiste.";
      },
    );
  }
}

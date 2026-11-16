import 'package:flutter/material.dart';
import '../../widgets/chat_view.dart';

/// Discussion avec un médecin. TODO : messages via le backend (table messages).
class ChatScreen extends StatelessWidget {
  final String doctorName;
  final String speciality;
  const ChatScreen({super.key, required this.doctorName, required this.speciality});

  @override
  Widget build(BuildContext context) {
    return ChatView(
      title: doctorName,
      subtitle: speciality,
      initial: [
        ChatMessage('Bonjour, comment puis-je vous aider ?', false, '09:12'),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../core/theme.dart';

class ChatMessage {
  final String text;
  final bool mine;
  final String time;
  ChatMessage(this.text, this.mine, this.time);
}

/// Écran de discussion réutilisé pour LupIA et pour le chat avec un médecin.
class ChatView extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<ChatMessage> initial;
  final List<String> quickReplies;

  /// Si fourni : génère la réponse automatique (ex. LupIA). Sinon, pas de réponse.
  /// TODO : remplacer par un appel au backend quand les routes existeront.
  final Future<String> Function(String message)? onSend;

  const ChatView({
    super.key,
    required this.title,
    required this.subtitle,
    this.initial = const [],
    this.quickReplies = const [],
    this.onSend,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final List<ChatMessage> _messages = [...widget.initial];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;

  String _now() {
    final n = TimeOfDay.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(t, true, _now()));
      _ctrl.clear();
    });
    _scrollDown();
    if (widget.onSend != null) {
      setState(() => _typing = true);
      final reply = await widget.onSend!(t);
      if (!mounted) return;
      setState(() {
        _typing = false;
        _messages.add(ChatMessage(reply, false, _now()));
      });
      _scrollDown();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(widget.title.characters.first,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(widget.subtitle,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('…',
                        style: TextStyle(color: AppColors.muted, fontSize: 18)),
                  );
                }
                final m = _messages[i];
                return Align(
                  alignment:
                      m.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: m.mine ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: m.mine
                          ? null
                          : Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(m.text,
                              style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      m.mine ? Colors.white : AppColors.text)),
                        ),
                        const SizedBox(height: 4),
                        Text(m.time,
                            style: TextStyle(
                                fontSize: 9,
                                color: m.mine
                                    ? Colors.white70
                                    : AppColors.muted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.quickReplies.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final q in widget.quickReplies)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(q, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        onPressed: () => _send(q),
                      ),
                    ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Écrivez votre message…',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, size: 18, color: Colors.white),
                      onPressed: () => _send(_ctrl.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

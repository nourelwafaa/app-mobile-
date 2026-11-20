import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/date_format.dart';
import 'package:lupus_plus/features/medecin/messages/chat_page.dart';
import 'package:lupus_plus/models/conversation.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// The conversations list ("Messages").
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final MedecinService _service = MedecinService();

  List<Conversation> _conversations = [];
  bool _chargement = true;
  bool _erreur = false;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
    // Reload when a message is sent or read (even from another screen).
    MedecinService.messagesChanged.addListener(_charger);
  }

  @override
  void dispose() {
    MedecinService.messagesChanged.removeListener(_charger);
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final liste = await _service.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = liste;
        _chargement = false;
        _erreur = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = true;
      });
    }
  }

  // Conversations matching the search text.
  List<Conversation> get _affichees {
    final q = _recherche.trim().toLowerCase();
    return _conversations
        .where((c) => c.patient.nom.toLowerCase().contains(q))
        .toList();
  }

  // Opens the chat full screen (the bottom bar is hidden, like in the design).
  void _ouvrirChat(Conversation c) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ChatPage(patient: c.patient)),
    );
  }

  // Purple round badge with the number of unread messages.
  Widget _badge(int nombre) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$nombre',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // One conversation row (flat, with a divider line under it).
  Widget _ligne(Conversation c) {
    final nonLu = c.nonLus > 0;
    final m = c.dernierMessage;
    // "Vous : ..." when the last message is the doctor's.
    final apercu = m.deMoi ? '${AppStrings.vous} : ${m.texte}' : m.texte;

    return InkWell(
      onTap: () => _ouvrirChat(c),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.iconSquare,
                  child: Text(
                    c.patient.initiale,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.patient.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        apercu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: nonLu ? FontWeight.w700 : FontWeight.w400,
                          color: nonLu ? AppColors.textDark : AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatHeureListe(m.date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                    if (nonLu) ...[
                      const SizedBox(height: 6),
                      _badge(c.nonLus),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.iconSquare),
        ],
      ),
    );
  }

  OutlineInputBorder _bordure(Color c) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c),
    );
  }

  // Spinner, error, empty message or the rows.
  List<Widget> _contenu(List<Conversation> affichees) {
    if (_chargement) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_erreur) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: Text(AppStrings.erreurChargement)),
        ),
      ];
    }
    if (affichees.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              AppStrings.aucuneConversation,
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          ),
        ),
      ];
    }
    return affichees.map(_ligne).toList();
  }

  @override
  Widget build(BuildContext context) {
    final affichees = _affichees;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Back arrow + centered title.
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      AppStrings.messages,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // balances the arrow
              ],
            ),
            const SizedBox(height: 12),

            // Search field.
            TextField(
              onChanged: (v) => setState(() => _recherche = v),
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: AppStrings.rechercherConversation,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: _bordure(AppColors.iconSquare),
                enabledBorder: _bordure(AppColors.iconSquare),
                focusedBorder: _bordure(AppColors.primary),
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              AppStrings.uniquementPatientsSuivis,
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            const SizedBox(height: 6),

            ..._contenu(affichees),
          ],
        ),
      ),
    );
  }
}
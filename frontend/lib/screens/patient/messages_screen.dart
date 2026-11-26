import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/date_format.dart';
import 'package:lupus_plus/models/message.dart';
import 'package:lupus_plus/providers/auth_provider.dart';
import 'package:lupus_plus/services/messages_service.dart';
import 'chat_screen.dart';

/// « Messages » côté patient : les médecins qui la suivent (séance 7).
/// Même design que la page Messages du médecin (features/medecin/messages/messages_page.dart).
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final MessagesService _service;

  List<MonMedecin> _medecins = [];
  bool _chargement = true;
  bool _erreur = false;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _service = MessagesService(context.read<AuthProvider>().api);
    _charger();
  }

  /// GET /api/patients/me/medecins
  Future<void> _charger() async {
    try {
      final liste = await _service.getMesMedecins();
      if (!mounted) return;
      setState(() {
        _medecins = liste;
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

  // Médecins correspondant à la recherche.
  List<MonMedecin> get _affiches {
    final q = _recherche.trim().toLowerCase();
    return _medecins.where((m) => m.nom.toLowerCase().contains(q)).toList();
  }

  // Ouvre la discussion en plein écran, puis recharge (non-lus à jour).
  Future<void> _ouvrirChat(MonMedecin m) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          medecinId: m.id,
          doctorName: m.docteur,
          speciality: m.specialite ?? '',
        ),
      ),
    );
    await _charger();
  }

  // Pastille violette avec le nombre de messages non lus.
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

  // Une ligne (plate, avec un trait en dessous).
  Widget _ligne(MonMedecin med) {
    final nonLu = med.nonLus > 0;
    final m = med.dernierMessage;
    // « Vous : ... » quand le dernier message est celui du patient.
    // Pas encore de message : on affiche la spécialité.
    final apercu = m == null
        ? (med.specialite ?? '')
        : (m.deMoi ? '${AppStrings.vous} : ${m.texte}' : m.texte);

    return InkWell(
      onTap: () => _ouvrirChat(med),
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
                    med.initiale,
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
                        med.docteur,
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
                    if (m != null)
                      Text(
                        formatHeureListe(m.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    if (nonLu) ...[
                      const SizedBox(height: 6),
                      _badge(med.nonLus),
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

  // Chargement, erreur, liste vide ou les lignes.
  List<Widget> _contenu(List<MonMedecin> affiches) {
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
    if (affiches.isEmpty) {
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
    return affiches.map(_ligne).toList();
  }

  @override
  Widget build(BuildContext context) {
    final affiches = _affiches;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _charger,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // Flèche retour + titre centré.
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
                  const SizedBox(width: 48), // équilibre la flèche
                ],
              ),
              const SizedBox(height: 12),

              // Champ de recherche.
              TextField(
                onChanged: (v) => setState(() => _recherche = v),
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: AppStrings.rechercherConversation,
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textGrey),
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
                AppStrings.uniquementMesMedecins,
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 6),

              ..._contenu(affiches),
            ],
          ),
        ),
      ),
    );
  }
}

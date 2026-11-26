import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/agenda_service.dart';
import '../../services/messages_service.dart';
import '../../services/traitement_service.dart';
import '../../widgets/common.dart';
import 'agenda_screen.dart';
import 'dossier_screen.dart';
import 'lupia_screen.dart';
import 'messages_screen.dart';
import 'stats_screen.dart';
import 'suivi_screen.dart';
import 'trouver_pro_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _go(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final prenom = context.watch<AuthProvider>().user?.prenom ?? '';

    final tiles = <(IconData, String, VoidCallback)>[
      (Icons.edit_note, 'Suivi du jour',
          () => _go(context, const SuiviScreen())),
      (Icons.bar_chart, 'Mes statistiques',
          () => _go(context, const StatsScreen())),
      (Icons.folder_open, 'Dossier médical',
          () => _go(context, const DossierScreen())),
      (Icons.location_on_outlined, 'Trouver un pro',
          () => _go(context, const TrouverProScreen())),
      (Icons.lightbulb_outline, 'Conseils et astuces',
          () => showSnack(context, 'Bientôt disponible')),
      (Icons.auto_awesome, 'LupIA', () => _go(context, const LupiaScreen())),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Icon(Icons.filter_vintage, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Lupus+',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 16)),
              ),
              // Messages avec ses médecins (séance 7), point rouge si non lus
              const _IconeMessages(),
              IconButton(
                icon: const Icon(Icons.notifications_none,
                    color: AppColors.primary),
                onPressed: () => showSnack(context, 'Aucune notification'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Bonjour, $prenom',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const Text('Prenez soin de vous aujourd\'hui',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 16),

          // Médicament (prises du jour) et prochain RDV : backend.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Aujourd'hui",
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 8),
                const _ProchainePrise(),
                const Divider(color: Colors.white24, height: 24),
                InkWell(
                  onTap: () => _go(context, const AgendaScreen()),
                  child: const _ProchainRdv(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.9,
            children: [
              for (final t in tiles)
                SectionCard(
                  onTap: t.$3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.soft,
                        child:
                            Icon(t.$1, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(t.$2,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ligne « médicament » de la carte Aujourd'hui :
/// première prise du jour pas encore faite (GET /api/patients/me/prises/aujourdhui).
class _ProchainePrise extends StatefulWidget {
  const _ProchainePrise();

  @override
  State<_ProchainePrise> createState() => _ProchainePriseState();
}

class _ProchainePriseState extends State<_ProchainePrise> {
  String _texte = 'Chargement…';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    String texte;
    try {
      final prises = await TraitementService(context.read<AuthProvider>().api)
          .getPrisesDuJour();
      final aFaire = prises.where((p) => !p.pris);
      if (prises.isEmpty) {
        texte = "Aucun médicament prévu aujourd'hui";
      } else if (aFaire.isEmpty) {
        texte = 'Toutes les prises du jour sont faites';
      } else {
        final p = aFaire.first;
        texte = '${p.nom} ${p.dosage}\nProchaine prise à ${p.heure}';
      }
    } catch (_) {
      texte = 'Traitements indisponibles';
    }
    if (mounted) setState(() => _texte = texte);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.medication, color: Colors.white, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text(_texte,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    ]);
  }
}

/// Ligne « RDV » de la carte Aujourd'hui :
/// prochain rendez-vous planifié (GET /api/patients/me/rendez-vous).
class _ProchainRdv extends StatefulWidget {
  const _ProchainRdv();

  @override
  State<_ProchainRdv> createState() => _ProchainRdvState();
}

class _ProchainRdvState extends State<_ProchainRdv> {
  String _texte = 'Chargement…';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    String texte;
    try {
      final rdvs = await AgendaService(context.read<AuthProvider>().api)
          .getMesRendezVous();
      if (rdvs.isEmpty) {
        texte = 'Aucun rendez-vous à venir';
      } else {
        final r = rdvs.first; // déjà trié du plus proche au plus lointain
        final titre = r.docteur != null ? 'RDV avec ${r.docteur}' : 'RDV : ${r.motif}';
        // "Jeudi 12 nov · 10:30"
        final quand =
            '${cap(DateFormat('EEEE d MMM', 'fr_FR').format(r.dateHeure).replaceAll('.', ''))}'
            ' · ${DateFormat('HH:mm').format(r.dateHeure)}';
        texte = '$titre\n$quand';
      }
    } catch (_) {
      texte = 'Rendez-vous indisponibles';
    }
    if (mounted) setState(() => _texte = texte);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.event, color: Colors.white, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text(_texte,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    ]);
  }
}

/// Icône « Messages » de l'accueil patient (séance 7), même design que chez le médecin :
/// point rouge s'il y a des messages non lus. Ouvre « Messages » (ses médecins).
class _IconeMessages extends StatefulWidget {
  const _IconeMessages();

  @override
  State<_IconeMessages> createState() => _IconeMessagesState();
}

class _IconeMessagesState extends State<_IconeMessages> {
  static const Color _rouge = Color(0xFFD4246B); // même rouge que chez le médecin
  bool _nonLus = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  /// GET /api/patients/me/medecins → total des non-lus
  Future<void> _charger() async {
    try {
      final n = await MessagesService(context.read<AuthProvider>().api)
          .nombreNonLusPatient();
      if (mounted) setState(() => _nonLus = n > 0);
    } catch (_) {
      // Pas de point rouge si le serveur ne répond pas.
    }
  }

  Future<void> _ouvrir() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const MessagesScreen()),
    );
    await _charger(); // les messages lus ne comptent plus
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _ouvrir,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
          if (_nonLus)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _rouge,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

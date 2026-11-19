import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'agenda_screen.dart';
import 'dossier_screen.dart';
import 'lupia_screen.dart';
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

          // TODO : données réelles quand les routes traitements / rendez-vous existeront
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
                const Row(children: [
                  Icon(Icons.medication, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Plaquenil 200 mg\nProchaine prise à 08:00',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ]),
                const Divider(color: Colors.white24, height: 24),
                InkWell(
                  onTap: () => _go(context, const AgendaScreen()),
                  child: const Row(children: [
                    Icon(Icons.event, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('RDV avec Dr Martin\nJeudi 12 nov · 10:30',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ]),
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

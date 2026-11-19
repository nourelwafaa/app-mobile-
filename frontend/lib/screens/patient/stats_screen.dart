import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/suivi.dart';
import '../../providers/auth_provider.dart';
import '../../services/suivi_service.dart';
import '../../widgets/common.dart';

/// Mes statistiques : GET /api/patients/me/stats?periode=7|30|90
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const _periodes = [7, 30, 90];
  int _period = 0;
  late final SuiviService _service;
  late Future<Stats> _future;

  @override
  void initState() {
    super.initState();
    _service = SuiviService(context.read<AuthProvider>().api);
    _future = _service.getStats(_periodes[_period]);
  }

  void _recharger() {
    setState(() => _future = _service.getStats(_periodes[_period]));
  }

  // 5.4 → "5,4" ; null → "–"
  String _fmt(double? v, {String unite = ''}) =>
      v == null ? '–' : '${NumberFormat('0.#', 'fr_FR').format(v)}$unite';

  // 2026-11-19 → "Jeu"
  String _jour(DateTime d) =>
      cap(DateFormat('E', 'fr_FR').format(d).replaceAll('.', ''));

  Widget _stat(String value, String label) => Expanded(
        child: SectionCard(
          child: Column(children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ]),
        ),
      );

  Widget _graphique(Stats s) {
    final avecJours = s.periode == 7;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Douleur par jour',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final j in s.jours)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: avecJours ? 8 : 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            // jour sans suivi : petite barre grise
                            height: (j.douleur == null ? 3 : j.douleur! * 10 + 3).toDouble(),
                            decoration: BoxDecoration(
                              color: j.douleur == null
                                  ? const Color(0xFFE6DDF0)
                                  : j.douleur! >= 8
                                      ? AppColors.primary
                                      : const Color(0xFFC9A5E6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          if (avecJours) ...[
                            const SizedBox(height: 4),
                            Text(_jour(j.date),
                                style: const TextStyle(
                                    fontSize: 9, color: AppColors.muted)),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vide() => SectionCard(
        child: const Column(children: [
          Icon(Icons.insights_outlined, color: AppColors.primary, size: 32),
          SizedBox(height: 8),
          Text('Pas encore de données',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
            'Remplissez votre suivi du jour pour voir vos statistiques ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ]),
      );

  Widget _tendance(String evolution) {
    final baisse = evolution == 'baisse';
    final texte = baisse
        ? 'Fatigue en baisse par rapport à la période précédente'
        : evolution == 'hausse'
            ? 'Fatigue en hausse par rapport à la période précédente'
            : 'Fatigue stable par rapport à la période précédente';
    final icone = baisse
        ? Icons.trending_down
        : evolution == 'hausse'
            ? Icons.trending_up
            : Icons.trending_flat;
    final couleur = baisse ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: baisse ? AppColors.successBg : AppColors.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icone, color: couleur, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texte, style: TextStyle(fontSize: 12, color: couleur)),
        ),
      ]),
    );
  }

  List<Widget> _contenu(Stats s) {
    if (s.joursRemplis == 0) return [_vide()];
    final symptome = s.symptomeNom == null
        ? 'Aucun symptôme noté'
        : '${s.symptomeNom} · ${s.symptomeJours} jour${(s.symptomeJours ?? 0) > 1 ? 's' : ''} sur ${s.periode}';
    return [
      _graphique(s),
      const SizedBox(height: 12),
      Row(children: [
        _stat(_fmt(s.moyDouleur), 'Douleur moy.'),
        const SizedBox(width: 8),
        _stat(_fmt(s.moyFatigue), 'Fatigue moy.'),
        const SizedBox(width: 8),
        _stat(_fmt(s.moySommeil, unite: ' h'), 'Sommeil moy.'),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Symptôme le plus fréquent',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(symptome,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      if (s.evolutionFatigue != null) ...[
        const SizedBox(height: 12),
        _tendance(s.evolutionFatigue!),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes statistiques')),
      body: SafeArea(
        child: FutureBuilder<Stats>(
          future: _future,
          builder: (context, snap) {
            final List<Widget> contenu;
            if (snap.connectionState != ConnectionState.done) {
              contenu = const [
                SizedBox(height: 40),
                Center(child: CircularProgressIndicator()),
              ];
            } else if (snap.hasError) {
              contenu = [
                const SizedBox(height: 24),
                Text(snap.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                      onPressed: _recharger, child: const Text('Réessayer')),
                ),
              ];
            } else {
              contenu = _contenu(snap.data!);
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                PillTabs(
                  labels: const ['7 jours', '30 jours', '3 mois'],
                  selected: _period,
                  onChanged: (i) {
                    _period = i;
                    _recharger();
                  },
                ),
                const SizedBox(height: 16),
                ...contenu,
              ],
            );
          },
        ),
      ),
    );
  }
}

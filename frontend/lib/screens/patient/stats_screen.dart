import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// Mes statistiques. TODO : alimenter depuis `suivi_quotidien` (GET à créer).
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _period = 0;
  static const _days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _douleur = [4.0, 6.0, 5.0, 7.0, 4.0, 5.0, 9.0];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes statistiques')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PillTabs(
              labels: const ['7 jours', '30 jours', '3 mois'],
              selected: _period,
              onChanged: (i) => setState(() => _period = i),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Douleur par jour',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 130,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (var i = 0; i < 7; i++)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 14,
                                height: _douleur[i] * 11,
                                decoration: BoxDecoration(
                                  color: _douleur[i] >= 8
                                      ? AppColors.primary
                                      : const Color(0xFFC9A5E6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_days[i],
                                  style: const TextStyle(
                                      fontSize: 9, color: AppColors.muted)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _stat('5,0', 'Douleur moy.'),
              const SizedBox(width: 8),
              _stat('6,1', 'Fatigue moy.'),
              const SizedBox(width: 8),
              _stat('7 h', 'Sommeil moy.'),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Symptôme le plus fréquent',
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  SizedBox(height: 4),
                  Text('Douleurs articulaires · 5 jours sur 7',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(children: [
                Icon(Icons.trending_down, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Fatigue en baisse par rapport à la semaine dernière',
                      style: TextStyle(fontSize: 12, color: AppColors.success)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// Mon agenda. TODO : GET/POST des rendez-vous quand les routes existeront.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final DateTime _today = DateTime.now();
  late DateTime _selected = _today;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _today.add(Duration(days: i)));
    return Scaffold(
      appBar: AppBar(title: const Text('Mon agenda')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(cap(DateFormat('MMMM yyyy', 'fr_FR').format(_selected)),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final d in days)
                  GestureDetector(
                    onTap: () => setState(() => _selected = d),
                    child: Container(
                      width: 42,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: DateUtils.isSameDay(d, _selected)
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(children: [
                        Text(
                          DateFormat('E', 'fr_FR')
                              .format(d)
                              .characters
                              .first
                              .toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              color: DateUtils.isSameDay(d, _selected)
                                  ? Colors.white70
                                  : AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text('${d.day}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: DateUtils.isSameDay(d, _selected)
                                    ? Colors.white
                                    : AppColors.text)),
                      ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('À venir',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const SectionCard(
              child: Row(children: [
                Icon(Icons.event, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Consultation de suivi',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('Dr Martin · Rhumatologue\nJeu 12 nov · 10:30',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            const SectionCard(
              child: Row(children: [
                Icon(Icons.science_outlined, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bilan sanguin',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('Labo Central\nVen 20 nov · 08:00',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: '+ Ajouter un rendez-vous',
              onPressed: () => showSnack(context, 'Bientôt disponible'),
            ),
          ],
        ),
      ),
    );
  }
}

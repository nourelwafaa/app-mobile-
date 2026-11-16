import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'agenda_screen.dart';

/// Rappels. Backend à venir : tables traitements / rendez-vous (03_traitements_rdv.sql).
class RappelsScreen extends StatefulWidget {
  const RappelsScreen({super.key});

  @override
  State<RappelsScreen> createState() => _RappelsScreenState();
}

class _Rappel {
  final String heure, titre, detail;
  bool pris;
  _Rappel(this.heure, this.titre, this.detail, {this.pris = false});
}

class _RappelsScreenState extends State<RappelsScreen> {
  int _tab = 0;
  final _meds = [
    _Rappel('08:00', 'Plaquenil', '200 mg · 1 comprimé', pris: true),
    _Rappel('14:00', 'Cortancyl', '5 mg · 1 comprimé'),
    _Rappel('20:00', 'Plaquenil', '200 mg · 1 comprimé'),
  ];
  final _rdv = [
    _Rappel('Jeu 12 nov', 'Consultation de suivi', 'Dr Martin · Rhumatologue'),
    _Rappel('Ven 20 nov', 'Bilan sanguin', 'Labo Central'),
  ];
  final _analyses = [
    _Rappel('Lun 23 nov', 'Bilan rénal', 'À jeun · 8h'),
  ];

  @override
  Widget build(BuildContext context) {
    final list = [_meds, _rdv, _analyses][_tab];
    return Scaffold(
      appBar: AppBar(title: const Text('Rappels'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PillTabs(
              labels: const ['Médicaments', 'Rendez-vous', 'Analyses'],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 16),
            for (final r in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  child: Row(children: [
                    SizedBox(
                      width: 64,
                      child: Text(r.heure,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.titre,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(r.detail,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    if (_tab == 0)
                      r.pris
                          ? const Chip(
                              label: Text('Pris',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.success)),
                              backgroundColor: AppColors.successBg,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact)
                          : TextButton(
                              onPressed: () => setState(() => r.pris = true),
                              style: TextButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white),
                              child: const Text('Marquer pris',
                                  style: TextStyle(fontSize: 10)),
                            ),
                  ]),
                ),
              ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: _tab == 0
                  ? '+ Ajouter un médicament'
                  : '+ Ajouter un rendez-vous',
              onPressed: () => _tab == 0
                  ? showSnack(context, 'Bientôt disponible')
                  : Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AgendaScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// Dossier médical. Backend à venir : 04_dossiers_recherche_messages.sql.
class DossierScreen extends StatefulWidget {
  const DossierScreen({super.key});

  @override
  State<DossierScreen> createState() => _DossierScreenState();
}

class _DossierScreenState extends State<DossierScreen> {
  int _tab = 0;
  static const _filtres = ['Tout', 'Ordonnances', 'Analyses', 'Comptes rendus'];
  static const _docs = [
    (1, Icons.description_outlined, 'Ordonnance Plaquenil', 'Ordonnance · 20 oct. 2026'),
    (2, Icons.science_outlined, 'Bilan sanguin complet', 'Analyse · 20 oct. 2026'),
    (3, Icons.assignment_outlined, 'Compte rendu de consultation', 'Compte rendu · 5 oct. 2026'),
    (2, Icons.image_outlined, 'Radio des mains', 'Imagerie · 1 sept. 2026'),
  ];

  @override
  Widget build(BuildContext context) {
    // catégorie du document : 1 = ordonnance, 2 = analyse, 3 = compte rendu
    final shown = _docs.where((d) => _tab == 0 || d.$1 == _tab).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Dossier médical')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PillTabs(
              labels: _filtres,
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 16),
            for (final d in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  onTap: () => showSnack(context, 'Aperçu bientôt disponible'),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: AppColors.soft,
                      child: Icon(d.$2, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.$3,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(d.$4,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ]),
                ),
              ),
            const SizedBox(height: 12),
            const Text('Partagé avec',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SectionCard(
              child: Row(children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text('M',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr Martin',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('Accès autorisé',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: AppColors.primary, size: 18),
                  onPressed: () => showSnack(context, 'Bientôt disponible'),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Ajouter un document',
              onPressed: () => showSnack(context, 'Bientôt disponible'),
            ),
          ],
        ),
      ),
    );
  }
}

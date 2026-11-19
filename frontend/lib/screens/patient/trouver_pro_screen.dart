import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'chat_screen.dart';

/// Trouver un professionnel. Backend à venir : table `professionnels`
/// (specialite, ville, latitude, longitude). Pour une vraie carte : google_maps_flutter.
class TrouverProScreen extends StatefulWidget {
  const TrouverProScreen({super.key});

  @override
  State<TrouverProScreen> createState() => _TrouverProScreenState();
}

class _TrouverProScreenState extends State<TrouverProScreen> {
  int _tab = 0;
  static const _pros = [
    ('Dr Martin', 'Rhumatologue', '0,8 km'),
    ('Dr Saliha', 'Médecine interne', '1,4 km'),
    ('Dr Benali', 'Dermatologue', '2,1 km'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trouver un professionnel')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const TextField(
              decoration: InputDecoration(
                hintText: 'Médecin, pharmacie, ville…',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            PillTabs(
              labels: const ['Médecins', 'Pharmacies', 'Cliniques', 'Labos'],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Stack(children: [
                Positioned(
                    left: 60,
                    top: 40,
                    child: Icon(Icons.location_on,
                        color: AppColors.primary, size: 30)),
                Positioned(
                    right: 80,
                    top: 70,
                    child: Icon(Icons.location_on,
                        color: AppColors.primary, size: 30)),
                Center(
                  child: Text('Carte (à brancher)',
                      style: TextStyle(color: AppColors.muted, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            for (final p in _pros)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChatScreen(
                              doctorName: p.$1, speciality: p.$2))),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(p.$1.split(' ').last[0],
                          style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.$1,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(p.$2,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Text(p.$3,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../widgets/common.dart';

// Couleurs pastel (mêmes que l'accueil)
const _fonds = [Color(0xFFE9DFFE), Color(0xFFFDE5F0), Color(0xFFE7F7F4)];
const _icones = [Color(0xFF7B5CE6), Color(0xFFE0526F), Color(0xFF2EAD8A)];
const _titre = Color(0xFF2B1B3F);
const _gris = Color(0xFF5E5668);

class _Conseil {
  final IconData icon;
  final String titre;
  final String texte;
  const _Conseil(this.icon, this.titre, this.texte);
}

// ---------- Contenu (texte fixe, aucune base de données) ----------

const _physique = [
  _Conseil(
    Icons.directions_walk,
    'Bouger en douceur',
    'Marche, natation, vélo, yoga ou tai-chi : visez 20 à 30 minutes, '
        'plusieurs fois par semaine, en augmentant petit à petit.',
  ),
  _Conseil(
    Icons.battery_alert,
    'Écouter sa fatigue',
    "Alternez effort et repos. Arrêtez-vous en cas de douleur vive ou "
        "d'essoufflement inhabituel.",
  ),
  _Conseil(
    Icons.wb_sunny_outlined,
    'Se protéger du soleil',
    'Les UV peuvent déclencher une poussée : crème SPF 50+, chapeau, '
        'vêtements couvrants, et évitez de sortir entre 10 h et 16 h.',
  ),
  _Conseil(
    Icons.accessibility_new,
    'Soulager les articulations',
    'Étirements doux et douche chaude le matin aident à réduire la '
        'raideur. Évitez les gestes brusques.',
  ),
  _Conseil(
    Icons.bedtime_outlined,
    'Bien dormir',
    'Gardez des horaires réguliers et visez 7 à 9 heures de sommeil. '
        'Coupez les écrans avant de vous coucher.',
  ),
  _Conseil(
    Icons.spa_outlined,
    'Gérer le stress',
    'Respiration lente, relaxation ou méditation : le stress peut '
        'favoriser les poussées.',
  ),
  _Conseil(
    Icons.smoke_free,
    'Arrêter le tabac',
    "Le tabac aggrave le lupus et peut réduire l'efficacité de certains "
        "traitements. Demandez de l'aide à votre médecin.",
  ),
];

const _alimentation = [
  _Conseil(
    Icons.eco_outlined,
    'Manger équilibré',
    "Fruits, légumes, céréales complètes, légumineuses et huile d'olive, "
        'à la manière du régime méditerranéen.',
  ),
  _Conseil(
    Icons.set_meal_outlined,
    'Poissons gras',
    'Saumon, sardines ou maquereau, riches en oméga-3, une à deux fois '
        'par semaine.',
  ),
  _Conseil(
    Icons.local_drink_outlined,
    'Calcium et vitamine D',
    'Produits laitiers, légumes verts, amandes : ils protègent les os, '
        'surtout sous corticoïdes. Demandez un dosage avant tout complément.',
  ),
  _Conseil(
    Icons.grain,
    'Limiter le sel',
    "Les corticoïdes font retenir l'eau et peuvent augmenter la tension. "
        'Peu de sel, peu de plats préparés.',
  ),
  _Conseil(
    Icons.monitor_weight_outlined,
    'Surveiller son poids',
    "Limitez sucres rapides et produits ultra-transformés : les "
        "corticoïdes peuvent augmenter l'appétit.",
  ),
  _Conseil(
    Icons.water_drop_outlined,
    "Bien s'hydrater",
    "Buvez de l'eau régulièrement, sauf avis contraire de votre médecin "
        '(atteinte rénale, par exemple).',
  ),
];

const _aEviter = [
  'Les germes de luzerne (alfalfa), qui pourraient favoriser les poussées',
  "L'alcool, selon votre traitement",
  'Les compléments « booster d\'immunité » (échinacée…) sans avis médical',
];

// ---------- Écran ----------

class ConseilsScreen extends StatefulWidget {
  const ConseilsScreen({super.key});

  @override
  State<ConseilsScreen> createState() => _ConseilsScreenState();
}

class _ConseilsScreenState extends State<ConseilsScreen> {
  int _tab = 0; // 0 = Physique, 1 = Alimentation

  @override
  Widget build(BuildContext context) {
    final liste = _tab == 0 ? _physique : _alimentation;

    return Scaffold(
      appBar: AppBar(title: const Text('Conseils et astuces')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            // ---- Introduction ----
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: _fonds[0],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -14,
                    top: 6,
                    child: Opacity(
                      opacity: 0.35,
                      child: Image.asset('assets/images/lupus_logo.png',
                          width: 110),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 250,
                          child: Text(
                            'Des gestes simples pour mieux vivre avec le lupus',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B1D66),
                                height: 1.3),
                          ),
                        ),
                        SizedBox(height: 6),
                        SizedBox(
                          width: 250,
                          child: Text(
                            "Des conseils d'hygiène de vie, à adapter avec "
                            'votre médecin.',
                            style: TextStyle(
                                fontSize: 12, color: _gris, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Onglets ----
            PillTabs(
              labels: const ['Physique', 'Alimentation'],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 16),

            // ---- Conseils ----
            for (var i = 0; i < liste.length; i++) ...[
              _ConseilCard(index: i, conseil: liste[i]),
              const SizedBox(height: 10),
            ],

            // ---- À éviter (onglet Alimentation) ----
            if (_tab == 1) ...[
              const _EviterCard(),
              const SizedBox(height: 10),
            ],

            // ---- Avertissement ----
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Color(0xFF8A5200)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ces conseils sont généraux et ne remplacent pas '
                      "l'avis de votre médecin. Parlez-en à votre équipe "
                      "médicale avant de changer d'alimentation ou de "
                      "reprendre une activité.",
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8A5200),
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConseilCard extends StatelessWidget {
  final int index;
  final _Conseil conseil;
  const _ConseilCard({required this.index, required this.conseil});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _fonds[index % 3],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(conseil.icon, size: 24, color: _icones[index % 3]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conseil.titre,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _titre)),
                const SizedBox(height: 3),
                Text(conseil.texte,
                    style: const TextStyle(
                        fontSize: 12, color: _gris, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EviterCard extends StatelessWidget {
  const _EviterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _fonds[1],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(190),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                size: 24, color: Color(0xFFE0526F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('À éviter ou à limiter',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _titre)),
                for (final t in _aEviter)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ',
                            style: TextStyle(
                                color: Color(0xFFE0526F), fontSize: 12)),
                        Expanded(
                          child: Text(t,
                              style: const TextStyle(
                                  fontSize: 12, color: _gris, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

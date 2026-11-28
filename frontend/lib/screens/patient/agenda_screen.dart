import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/rendez_vous.dart';
import '../../providers/auth_provider.dart';
import '../../services/agenda_service.dart';
import '../../widgets/common.dart';

/// Mon agenda : rendez-vous et analyses à venir (créés par le médecin, backend).
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

/// Une ligne « À venir » (rendez-vous ou analyse)
class _Element {
  final IconData icone;
  final String titre, detail;
  final DateTime dateHeure;
  const _Element(this.icone, this.titre, this.detail, this.dateHeure);
}

class _AgendaScreenState extends State<AgendaScreen> {
  final DateTime _today = DateTime.now();
  late DateTime _selected = _today;

  bool _chargement = true;
  String? _erreur;
  List<_Element> _elements = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  // "Jeu 12 nov · 10:30"
  static String _quand(DateTime d) =>
      '${cap(DateFormat('EEE d MMM', 'fr_FR').format(d).replaceAll('.', ''))}'
      ' · ${DateFormat('HH:mm').format(d)}';

  /// GET /api/patients/me/rendez-vous + /api/patients/me/analyses
  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final service = AgendaService(context.read<AuthProvider>().api);
      final r = await Future.wait([
        service.getMesRendezVous(),
        service.getMesAnalyses(),
      ]);
      final rdvs = r[0] as List<RdvPatient>;
      final analyses = r[1] as List<Analyse>;
      final elements = <_Element>[
        for (final v in rdvs)
          _Element(
            Icons.event,
            v.motif,
            [
              [v.docteur ?? v.lieu, v.medecinSpecialite]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              _quand(v.dateHeure),
            ].where((s) => s.isNotEmpty).join('\n'),
            v.dateHeure,
          ),
        for (final a in analyses)
          _Element(
            Icons.science_outlined,
            a.type,
            [a.laboratoire, _quand(a.dateHeure)]
                .whereType<String>()
                .where((s) => s.isNotEmpty)
                .join('\n'),
            a.dateHeure,
          ),
      ]..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
      if (!mounted) return;
      setState(() {
        _elements = elements;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.toString();
        _chargement = false;
      });
    }
  }

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
            if (_chargement)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erreur != null)
              Column(children: [
                Text(_erreur!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                TextButton(onPressed: _charger, child: const Text('Réessayer')),
              ])
            else if (_elements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Aucun rendez-vous ni analyse à venir',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              )
            else
              for (final e in _elements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    child: Row(children: [
                      Icon(e.icone, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.titre,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                            Text(e.detail,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
            // Pas de bouton « Ajouter un rendez-vous » : c'est le médecin qui crée les RDV.
          ],
        ),
      ),
    );
  }
}

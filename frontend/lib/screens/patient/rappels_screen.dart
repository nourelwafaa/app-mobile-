import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../features/medecin/patients/add_traitement_page.dart';
import '../../providers/auth_provider.dart';
import '../../services/traitement_service.dart';
import '../../widgets/common.dart';
import 'agenda_screen.dart';

/// Rappels. Onglet Médicaments : backend (prises du jour).
/// Rendez-vous / Analyses : fausses données jusqu'à la séance 4.
class RappelsScreen extends StatefulWidget {
  const RappelsScreen({super.key});

  @override
  State<RappelsScreen> createState() => _RappelsScreenState();
}

class _Rappel {
  final String heure, titre, detail;
  final int? rappelId; // id du rappel côté backend (médicaments seulement)
  bool pris;
  _Rappel(this.heure, this.titre, this.detail, {this.pris = false, this.rappelId});
}

class _RappelsScreenState extends State<RappelsScreen> {
  late final TraitementService _service;
  int _tab = 0;
  bool _chargement = true;
  String? _erreur;
  final Set<int> _envoiEnCours = {}; // rappels en cours d'envoi « Marquer pris »

  List<_Rappel> _meds = [];

  @override
  void initState() {
    super.initState();
    _service = TraitementService(context.read<AuthProvider>().api);
    _chargerMeds();
  }

  /// GET /api/patients/me/prises/aujourdhui
  Future<void> _chargerMeds() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final prises = await _service.getPrisesDuJour();
      if (!mounted) return;
      setState(() {
        _meds = [
          for (final p in prises)
            _Rappel(p.heure, p.nom, p.dosage, pris: p.pris, rappelId: p.rappelId),
        ];
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

  /// POST /api/patients/me/prises
  Future<void> _marquerPris(_Rappel r) async {
    final id = r.rappelId;
    if (id == null || _envoiEnCours.contains(id)) return;
    setState(() => _envoiEnCours.add(id));
    try {
      await _service.marquerPrise(id);
      if (!mounted) return;
      setState(() => r.pris = true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _envoiEnCours.remove(id));
    }
  }

  Future<void> _ajouterMedicament() async {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => const AddTraitementPage.patient()),
    );
    if (ok != true || !mounted) return;
    showSnack(context, 'Médicament ajouté');
    await _chargerMeds();
  }

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
            if (_tab == 0 && _chargement)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tab == 0 && _erreur != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(children: [
                  Text(_erreur!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  TextButton(onPressed: _chargerMeds, child: const Text('Réessayer')),
                ]),
              )
            else if (_tab == 0 && _meds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text("Aucune prise de médicament prévue aujourd'hui",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
            if (!(_tab == 0 && (_chargement || _erreur != null)))
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
                              onPressed: _envoiEnCours.contains(r.rappelId)
                                  ? null
                                  : () => _marquerPris(r),
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
                  ? _ajouterMedicament()
                  : Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AgendaScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

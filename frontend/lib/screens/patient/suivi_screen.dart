import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/suivi.dart';
import '../../providers/auth_provider.dart';
import '../../services/suivi_service.dart';
import '../../widgets/common.dart';

/// Suivi du jour : POST /api/patients/me/suivi
/// Pré-rempli avec GET /api/patients/me/suivi/aujourdhui s'il a déjà été fait.
class SuiviScreen extends StatefulWidget {
  final bool showBack;
  const SuiviScreen({super.key, this.showBack = true});

  @override
  State<SuiviScreen> createState() => _SuiviScreenState();
}

class _SuiviScreenState extends State<SuiviScreen> {
  double _douleur = 5, _fatigue = 5, _humeur = 5;
  final _sommeil = TextEditingController();
  final _remarque = TextEditingController();
  final _symptomes = <String>{};
  static const _tous = [
    'Douleurs articulaires',
    'Fatigue',
    'Fièvre',
    'Éruptions cutanées',
    'Maux de tête',
  ];

  late final SuiviService _service;
  bool _chargement = true; // lecture du suivi d'aujourd'hui
  bool _envoi = false; // enregistrement en cours
  bool _dejaFait = false; // un suivi existe déjà aujourd'hui

  @override
  void initState() {
    super.initState();
    _service = SuiviService(context.read<AuthProvider>().api);
    _charger();
  }

  @override
  void dispose() {
    _sommeil.dispose();
    _remarque.dispose();
    super.dispose();
  }

  String _heures(double h) =>
      h == h.roundToDouble() ? h.toInt().toString() : h.toString();

  Future<void> _charger() async {
    try {
      final s = await _service.getAujourdhui();
      if (!mounted || s == null) return;
      setState(() {
        _douleur = s.douleur.toDouble();
        _fatigue = s.fatigue.toDouble();
        _humeur = s.humeur.toDouble();
        _sommeil.text = s.sommeilHeures == null ? '' : _heures(s.sommeilHeures!);
        _remarque.text = s.remarque ?? '';
        _symptomes
          ..clear()
          ..addAll(s.symptomes);
        _dejaFait = true;
      });
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _save() async {
    final texte = _sommeil.text.trim().replaceAll(',', '.');
    final sommeil = texte.isEmpty ? null : double.tryParse(texte);
    if (texte.isNotEmpty && (sommeil == null || sommeil < 0 || sommeil > 24)) {
      showSnack(context, "Sommeil : entrez un nombre d'heures entre 0 et 24",
          error: true);
      return;
    }

    setState(() => _envoi = true);
    try {
      final remarque = _remarque.text.trim();
      await _service.enregistrer(SuiviJour(
        douleur: _douleur.round(),
        fatigue: _fatigue.round(),
        humeur: _humeur.round(),
        sommeilHeures: sommeil,
        remarque: remarque.isEmpty ? null : remarque,
        symptomes: _symptomes.toList(),
      ));
      if (!mounted) return;
      setState(() => _dejaFait = true);
      showSnack(context, 'Suivi du jour enregistré');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = cap(DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi du jour'),
        automaticallyImplyLeading: widget.showBack,
      ),
      body: SafeArea(
        child: _chargement
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(date,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted)),
                  if (_dejaFait) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Déjà rempli aujourd'hui : vous pouvez le modifier.",
                        style: TextStyle(fontSize: 11, color: AppColors.primary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  LabeledSlider(
                    label: 'Douleur',
                    value: _douleur,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    valueText: '${_douleur.round()} / 10',
                    onChanged: (v) => setState(() => _douleur = v),
                  ),
                  LabeledSlider(
                    label: 'Fatigue',
                    value: _fatigue,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    valueText: '${_fatigue.round()} / 10',
                    onChanged: (v) => setState(() => _fatigue = v),
                  ),
                  LabeledSlider(
                    label: 'Humeur',
                    value: _humeur,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    valueText: '${_humeur.round()} / 10',
                    onChanged: (v) => setState(() => _humeur = v),
                  ),
                  const SizedBox(height: 8),
                  const Text('Sommeil (heures)',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _sommeil,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'Ex : 7,5'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Symptômes',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s in _tous)
                        FilterChip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          selected: _symptomes.contains(s),
                          showCheckmark: false,
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                              color: _symptomes.contains(s)
                                  ? Colors.white
                                  : AppColors.primary),
                          side: const BorderSide(color: AppColors.primary),
                          onSelected: (v) => setState(() =>
                              v ? _symptomes.add(s) : _symptomes.remove(s)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Remarque',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _remarque,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        hintText: 'Comment vous sentez-vous ?'),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _dejaFait ? 'Mettre à jour' : 'Enregistrer',
                    loading: _envoi,
                    onPressed: _save,
                  ),
                ],
              ),
      ),
    );
  }
}

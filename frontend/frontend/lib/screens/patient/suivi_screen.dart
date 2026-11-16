import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// Suivi du jour. Backend à venir : table `suivi_quotidien` (douleur, fatigue,
/// humeur, sommeil_heures, remarque) + table `symptomes`.
class SuiviScreen extends StatefulWidget {
  final bool showBack;
  const SuiviScreen({super.key, this.showBack = true});

  @override
  State<SuiviScreen> createState() => _SuiviScreenState();
}

class _SuiviScreenState extends State<SuiviScreen> {
  double _douleur = 6, _fatigue = 7, _humeur = 5;
  final _sommeil = TextEditingController(text: '7.5');
  final _remarque = TextEditingController();
  final _symptomes = <String>{'Douleurs articulaires', 'Fatigue'};
  static const _tous = [
    'Douleurs articulaires',
    'Fatigue',
    'Fièvre',
    'Éruptions cutanées',
    'Maux de tête',
  ];

  @override
  void dispose() {
    _sommeil.dispose();
    _remarque.dispose();
    super.dispose();
  }

  void _save() {
    // TODO : POST /api/patients/me/suivi quand la route existera
    // body: { douleur, fatigue, humeur, sommeil_heures, remarque, symptomes }
    showSnack(context, 'Suivi enregistré (local)');
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(date,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _sommeil,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            const Text('Symptômes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                    onSelected: (v) => setState(
                        () => v ? _symptomes.add(s) : _symptomes.remove(s)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Remarque',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _remarque,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Comment vous sentez-vous ?'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Enregistrer', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

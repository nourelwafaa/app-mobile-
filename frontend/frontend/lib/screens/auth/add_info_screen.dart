import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';

/// Écran "Ajouter des informations" -> PUT /api/patients/me/infos
/// [onboarding] = true juste après l'inscription, false depuis le profil.
class AddInfoScreen extends StatefulWidget {
  final bool onboarding;
  const AddInfoScreen({super.key, this.onboarding = false});

  @override
  State<AddInfoScreen> createState() => _AddInfoScreenState();
}

class _AddInfoScreenState extends State<AddInfoScreen> {
  static const _groupes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  String _sexe = 'femme';
  double _poids = 70;
  double _taille = 170;
  String? _groupe;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  Future<void> _loadExisting() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.loadProfile(); // récupère aussi l'âge calculé par le backend
    } catch (_) {
      return;
    }
    final p = auth.profile;
    if (p == null || !mounted) return;
    setState(() {
      _sexe = p.sexe ?? _sexe;
      _poids = p.poids ?? _poids;
      _taille = p.taille ?? _taille;
      _groupe = p.groupeSanguin ?? _groupe;
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().saveInfos(
            sexe: _sexe,
            poids: double.parse(_poids.toStringAsFixed(1)),
            taille: double.parse(_taille.toStringAsFixed(1)),
            groupeSanguin: _groupe,
          );
      if (!mounted) return;
      if (widget.onboarding) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        Navigator.of(context).pop();
        showSnack(context, 'Informations enregistrées');
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _sexeButton(String value, String label) {
    final selected = _sexe == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sexe = value),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.primary)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final age = context.watch<AuthProvider>().profile?.age;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des informations'),
        automaticallyImplyLeading: !widget.onboarding,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quel est votre sexe ?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                _sexeButton('homme', 'Homme'),
                const SizedBox(width: 10),
                _sexeButton('femme', 'Femme'),
              ]),
              const SizedBox(height: 18),
              const Text('Âge',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SectionCard(
                child: Text(
                  age == null
                      ? 'Calculé depuis votre date de naissance'
                      : '$age ans · calculé depuis votre date de naissance',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 18),
              LabeledSlider(
                label: 'Poids (kg)',
                value: _poids,
                min: 20,
                max: 200,
                valueText: '${_poids.round()} kg',
                onChanged: (v) => setState(() => _poids = v),
              ),
              LabeledSlider(
                label: 'Taille (cm)',
                value: _taille,
                min: 100,
                max: 220,
                valueText: '${_taille.round()} cm',
                onChanged: (v) => setState(() => _taille = v),
              ),
              const SizedBox(height: 8),
              const Text('Groupe sanguin',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _groupe,
                hint: const Text('Choisir'),
                items: [
                  for (final g in _groupes)
                    DropdownMenuItem(value: g, child: Text(g)),
                ],
                onChanged: (v) => setState(() => _groupe = v),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: widget.onboarding ? 'Terminer' : 'Enregistrer',
                loading: _loading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

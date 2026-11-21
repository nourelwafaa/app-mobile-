import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/theme/form_style.dart';
import 'package:lupus_plus/models/resultat_recherche.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// Add a patient: search a registered patient by email or phone, then add him.
// Closes with true when a patient was added.
class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final MedecinService _service = MedecinService();
  final _formKey = GlobalKey<FormState>();
  final _saisieCtrl = TextEditingController();

  ResultatRecherche? _resultat; // patient found
  String? _erreur; // message when nothing was found
  bool _recherche = false;
  bool _ajout = false;

  @override
  void dispose() {
    _saisieCtrl.dispose();
    super.dispose();
  }

  String? _obligatoire(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.champObligatoire;
    return null;
  }

  Future<void> _rechercher() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus(); // hides the keyboard

    setState(() {
      _recherche = true;
      _resultat = null;
      _erreur = null;
    });

    final r = await _service.rechercherPatient(_saisieCtrl.text);
    if (!mounted) return;
    setState(() {
      _recherche = false;
      _resultat = r;
      _erreur = r == null ? AppStrings.patientIntrouvable : null;
    });
  }

  Future<void> _ajouter() async {
    final r = _resultat;
    if (r == null || r.dejaSuivi) return;

    setState(() => _ajout = true);
    await _service.ajouterPatient(r.patient);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // Card showing the patient found.
  Widget _carteResultat(ResultatRecherche r) {
    final p = r.patient;
    final infos = [
      if (p.age != null) '${p.age} ${AppStrings.ans}',
      if (p.groupeSanguin != null) '${AppStrings.groupe} ${p.groupeSanguin}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.iconSquare),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.iconSquare,
                child: Text(
                  p.initiale,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nom,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      infos,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (r.dejaSuivi)
            const Text(
              AppStrings.dejaDansListe,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.warningText,
              ),
            )
          else
            ElevatedButton(
              onPressed: _ajout ? null : _ajouter,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: _ajout
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      AppStrings.ajouterAMesPatients,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: formAppBar(AppStrings.actionAjouterPatient),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              TextFormField(
                controller: _saisieCtrl,
                validator: _obligatoire,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _rechercher(),
                // Typing again clears the previous result.
                onChanged: (_) {
                  if (_resultat != null || _erreur != null) {
                    setState(() {
                      _resultat = null;
                      _erreur = null;
                    });
                  }
                },
                style: formTextStyle,
                decoration: formDecoration(
                  AppStrings.emailOuTelephone,
                  Icons.alternate_email,
                ),
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: _recherche ? null : _rechercher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _recherche
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        AppStrings.rechercher,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 24),

              if (_erreur != null)
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _erreur!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              if (_resultat != null) _carteResultat(_resultat!),
            ],
          ),
        ),
      ),
    );
  }
}
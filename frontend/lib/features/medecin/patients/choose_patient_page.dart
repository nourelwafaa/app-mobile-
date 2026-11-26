import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/models/patient.dart';
import 'package:lupus_plus/providers/auth_provider.dart';
import 'package:lupus_plus/services/espace_medecin_service.dart';
import 'package:provider/provider.dart';

// "Choisir un patient": search + list. Closes with the chosen Patient
// (null if the doctor goes back).
class ChoosePatientPage extends StatefulWidget {
  const ChoosePatientPage({super.key});

  @override
  State<ChoosePatientPage> createState() => _ChoosePatientPageState();
}

class _ChoosePatientPageState extends State<ChoosePatientPage> {
  List<Patient> _patients = [];
  bool _chargement = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    // GET /api/medecin/patients (en cas d'erreur : liste vide)
    final service = EspaceMedecinService(context.read<AuthProvider>().api);
    List<Patient> liste;
    try {
      liste = await service.getPatients();
    } catch (_) {
      liste = [];
    }
    liste.sort((a, b) => a.nom.compareTo(b.nom)); // alphabetical
    if (!mounted) return;
    setState(() {
      _patients = liste;
      _chargement = false;
    });
  }

  // Patients matching the search text.
  List<Patient> get _affiches {
    final q = _recherche.trim().toLowerCase();
    return _patients.where((p) => p.nom.toLowerCase().contains(q)).toList();
  }

  OutlineInputBorder _bordure(Color c) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c),
    );
  }

  // One patient card: tap = choose.
  Widget _ligne(Patient p) {
    final infos = [
      if (p.age != null) '${p.age} ${AppStrings.ans}',
      if (p.groupeSanguin != null) '${AppStrings.groupe} ${p.groupeSanguin}',
    ].join(' · ');

    return GestureDetector(
      onTap: () => Navigator.pop(context, p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.iconSquare),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.iconSquare,
              child: Text(
                p.initiale,
                style: const TextStyle(
                  fontSize: 17,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  List<Widget> _contenu(List<Patient> affiches) {
    if (_chargement) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (affiches.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              AppStrings.aucunPatient,
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          ),
        ),
      ];
    }
    return affiches.map(_ligne).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Back arrow + centered title.
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      AppStrings.choisirPatient,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              onChanged: (v) => setState(() => _recherche = v),
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: AppStrings.rechercherPatient,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: _bordure(AppColors.iconSquare),
                enabledBorder: _bordure(AppColors.iconSquare),
                focusedBorder: _bordure(AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            ..._contenu(_affiches),
          ],
        ),
      ),
    );
  }
}
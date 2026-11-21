import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/date_format.dart';
import 'package:lupus_plus/features/medecin/patients/patient_fiche_page.dart';
import 'package:lupus_plus/features/medecin/patients/widgets/chip_filtre.dart';
import 'package:lupus_plus/models/patient.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// The 3 filters of the list.
enum _Filtre { tous, alerte, rdv }

// "Mes patients": search + filters + list.
class PatientsPage extends StatefulWidget {
  final VoidCallback onRetour; // back arrow: goes to the Accueil tab

  const PatientsPage({super.key, required this.onRetour});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final MedecinService _service = MedecinService();

  List<Patient> _patients = [];
  Set<int> _idsRdvSemaine = {}; // patients with an appointment this week
  bool _chargement = true;
  bool _erreur = false;

  String _recherche = '';
  _Filtre _filtre = _Filtre.tous;

  @override
  void initState() {
    super.initState();
    _charger();
    // Reload when a patient or an appointment is added.
    MedecinService.patientsChanged.addListener(_charger);
    MedecinService.rdvChanged.addListener(_charger);
    MedecinService.alertesChanged.addListener(_charger);
  }
  @override
  void dispose() {
    MedecinService.patientsChanged.removeListener(_charger);
    MedecinService.rdvChanged.removeListener(_charger);
    MedecinService.alertesChanged.removeListener(_charger);
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final r = await Future.wait([
        _service.getPatients(),
        _service.getPatientsAvecRdvSemaine(),
      ]);
      if (!mounted) return;
      setState(() {
        _patients = r[0] as List<Patient>;
        _idsRdvSemaine = r[1] as Set<int>;
        _chargement = false;
        _erreur = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = true;
      });
    }
  }

  // Patients after the filter chip and the search text, most recent first.
  List<Patient> get _affiches {
    final q = _recherche.trim().toLowerCase();
    final liste = _patients.where((p) {
      final okFiltre = switch (_filtre) {
        _Filtre.tous => true,
        _Filtre.alerte => p.alerte != NiveauAlerte.aucune,
        _Filtre.rdv => _idsRdvSemaine.contains(p.id),
      };
      return okFiltre && p.nom.toLowerCase().contains(q);
    }).toList();
    liste.sort((a, b) => b.derniereActivite.compareTo(a.derniereActivite));
    return liste;
  }

  // Opens the patient file, then refreshes the counters.
  Future<void> _ouvrirFiche(Patient p) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PatientFichePage(patient: p)),
    );
    if (mounted) _charger();
  }

  // Small "Alerte" label (red = high, orange = medium).
  Widget _chipAlerte(NiveauAlerte niveau) {
    final eleve = niveau == NiveauAlerte.eleve;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: eleve ? AppColors.dangerBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppStrings.alerte,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: eleve ? AppColors.danger : AppColors.warningText,
        ),
      ),
    );
  }

  // One patient card.
  Widget _ligne(Patient p) {
    // "26 ans · Groupe AB+"
    final infos = [
      if (p.age != null) '${p.age} ${AppStrings.ans}',
      if (p.groupeSanguin != null) '${AppStrings.groupe} ${p.groupeSanguin}',
    ].join(' · ');

    return GestureDetector(
      onTap: () => _ouvrirFiche(p),
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
                  const SizedBox(height: 2),
                  Text(
                    infos,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  Text(
                    '${AppStrings.suiviDuJour} : ${formatSuivi(p.derniereActivite)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (p.alerte != NiveauAlerte.aucune) ...[
              const SizedBox(width: 8),
              _chipAlerte(p.alerte),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  // Rounded border of the search field.
  OutlineInputBorder _bordure(Color c) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c),
    );
  }

  // Spinner, error, empty message or the cards.
  List<Widget> _contenu(List<Patient> affiches) {
    if (_chargement) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_erreur) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: Text(AppStrings.erreurChargement)),
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
    final affiches = _affiches;
    final nbAlerte =
        _patients.where((p) => p.alerte != NiveauAlerte.aucune).length;
    final nbRdv = _patients.where((p) => _idsRdvSemaine.contains(p.id)).length;

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
                  onPressed: widget.onRetour,
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      AppStrings.mesPatients,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // balances the arrow
              ],
            ),
            const SizedBox(height: 12),

            // Search field.
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
            const SizedBox(height: 12),

            // Filter chips with counters.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChipFiltre(
                    label: '${AppStrings.filtreTous} · ${_patients.length}',
                    selected: _filtre == _Filtre.tous,
                    onTap: () => setState(() => _filtre = _Filtre.tous),
                  ),
                  const SizedBox(width: 8),
                  ChipFiltre(
                    label: '${AppStrings.filtreAlerte} · $nbAlerte',
                    selected: _filtre == _Filtre.alerte,
                    onTap: () => setState(() => _filtre = _Filtre.alerte),
                  ),
                  const SizedBox(width: 8),
                  ChipFiltre(
                    label: '${AppStrings.filtreRdvSemaine} · $nbRdv',
                    selected: _filtre == _Filtre.rdv,
                    onTap: () => setState(() => _filtre = _Filtre.rdv),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ..._contenu(affiches),
          ],
        ),
      ),
    );
  }
}
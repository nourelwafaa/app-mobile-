import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/date_format.dart';
import 'package:lupus_plus/features/medecin/patients/patient_fiche_page.dart';
import 'package:lupus_plus/features/medecin/patients/widgets/chip_filtre.dart';
import 'package:lupus_plus/models/alerte.dart';
import 'package:lupus_plus/models/patient.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// The alerts page: "À traiter" and "Traitées" tabs.
class AlertesPage extends StatefulWidget {
  const AlertesPage({super.key});

  @override
  State<AlertesPage> createState() => _AlertesPageState();
}

class _AlertesPageState extends State<AlertesPage> {
  final MedecinService _service = MedecinService();

  List<Alerte> _alertes = [];
  bool _chargement = true;
  bool _erreur = false;
  bool _aTraiter = true; // selected tab: true = "À traiter"

  @override
  void initState() {
    super.initState();
    _charger();
    // Reload when an alert is handled.
    MedecinService.alertesChanged.addListener(_charger);
  }

  @override
  void dispose() {
    MedecinService.alertesChanged.removeListener(_charger);
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final liste = await _service.getAlertes();
      if (!mounted) return;
      setState(() {
        _alertes = liste;
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

  // "Marquer comme traitée".
  Future<void> _traiter(Alerte a) async {
    await _service.marquerAlerteTraitee(a.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.alerteTraitee)),
    );
  }

  // Tap on a card: opens the patient file.
  Future<void> _ouvrirFiche(Alerte a) async {
    final patient = await _service.getPatient(a.patientId);
    if (patient == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PatientFichePage(patient: patient)),
    );
  }

  // Level label: red (high), orange (medium), blue (low).
  Widget _chipNiveau(NiveauAlerte niveau) {
    final (texte, fond, couleur) = switch (niveau) {
      NiveauAlerte.eleve => (
          AppStrings.niveauEleve,
          AppColors.dangerBg,
          AppColors.danger,
        ),
      NiveauAlerte.moyen => (
          AppStrings.niveauMoyen,
          AppColors.warningBg,
          AppColors.warningText,
        ),
      _ => (
          AppStrings.niveauFaible,
          AppColors.infoBg,
          AppColors.infoText,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: couleur,
        ),
      ),
    );
  }

  // One alert card.
  Widget _carte(Alerte a) {
    return GestureDetector(
      onTap: () => _ouvrirFiche(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.iconSquare),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name + date, level label on the right.
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.iconSquare,
                  child: Text(
                    a.patientNom[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.patientNom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        formatActivite(a.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                _chipNiveau(a.niveau),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              a.message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Button (pending) or "✓ Traitée" (handled).
            if (!a.traitee)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => _traiter(a),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    AppStrings.marquerTraitee,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: AppColors.successText),
                  SizedBox(width: 6),
                  Text(
                    AppStrings.traitee,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.successText,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Spinner, error, empty message or the cards.
  List<Widget> _contenu(List<Alerte> affichees) {
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
    if (affichees.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              AppStrings.aucuneAlerte,
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          ),
        ),
      ];
    }
    return affichees.map(_carte).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nbATraiter = _alertes.where((a) => !a.traitee).length;
    final affichees = _alertes.where((a) => a.traitee != _aTraiter).toList();

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
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      AppStrings.alertes,
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

            // Tabs.
            Row(
              children: [
                ChipFiltre(
                  label: '${AppStrings.aTraiter} · $nbATraiter',
                  selected: _aTraiter,
                  onTap: () => setState(() => _aTraiter = true),
                ),
                const SizedBox(width: 8),
                ChipFiltre(
                  label: AppStrings.traitees,
                  selected: !_aTraiter,
                  onTap: () => setState(() => _aTraiter = false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ..._contenu(affichees),
          ],
        ),
      ),
    );
  }
}
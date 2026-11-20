import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/features/medecin/agenda/new_rdv_page.dart';
import 'package:lupus_plus/features/medecin/patients/add_document_page.dart';
import 'package:lupus_plus/features/medecin/patients/add_traitement_page.dart';
import 'package:lupus_plus/features/medecin/patients/widgets/segmented_tabs.dart';
import 'package:lupus_plus/features/medecin/messages/chat_page.dart';
import 'package:lupus_plus/models/document_medical.dart';
import 'package:lupus_plus/models/patient.dart';
import 'package:lupus_plus/models/traitement.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// The 3 tabs of the patient file.
enum _Onglet { suivi, traitements, documents }

// Weekday letters, Monday first.
const List<String> _lettres = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

// "Fiche patient": header, alert, 3 tabs and 2 action buttons.
class PatientFichePage extends StatefulWidget {
  final Patient patient;

  const PatientFichePage({super.key, required this.patient});

  @override
  State<PatientFichePage> createState() => _PatientFichePageState();
}

class _PatientFichePageState extends State<PatientFichePage> {
  final MedecinService _service = MedecinService();
  final DateFormat _dateFr = DateFormat('d MMM yyyy', 'fr_FR');

  _Onglet _onglet = _Onglet.suivi;
  TypeDocument? _filtreDoc; // null = all documents

  List<Traitement> _traitements = [];
  List<DocumentMedical> _documents = [];
  bool _chargement = true;

  Patient get _p => widget.patient;

  // Navigator that covers the whole screen (hides the bottom bar).
  NavigatorState get _racine => Navigator.of(context, rootNavigator: true);

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final r = await Future.wait([
      _service.getTraitements(_p.id),
      _service.getDocuments(_p.id),
    ]);
    if (!mounted) return;
    setState(() {
      _traitements = r[0] as List<Traitement>;
      _documents = r[1] as List<DocumentMedical>;
      _chargement = false;
    });
  }

  // ---------- Actions ----------

  Future<void> _ajouterTraitement() async {
    final ok = await _racine.push<bool>(
      MaterialPageRoute(builder: (_) => AddTraitementPage(patientId: _p.id)),
    );
    if (ok != true || !mounted) return;
    await _charger();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.medicamentAjoute)),
    );
  }

  Future<void> _ajouterDocument() async {
    final ok = await _racine.push<bool>(
      MaterialPageRoute(builder: (_) => AddDocumentPage(patientId: _p.id)),
    );
    if (ok != true || !mounted) return;
    await _charger();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.documentAjoute)),
    );
  }

  // Opens the chat with this patient (full screen).
  void _ouvrirMessage() {
    _racine.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(patient: _p, depuisFiche: true),
      ),
    );
  }

  // Opens "Nouveau rendez-vous" with this patient preselected.
  Future<void> _planifierRdv() async {
    final patients = await _service.getPatients();
    if (!mounted) return;
    final date = await _racine.push<DateTime>(
      MaterialPageRoute(
        builder: (_) => NewRdvPage(
          patients: patients,
          dateInitiale: DateTime.now(),
          patientIdInitial: _p.id,
        ),
      ),
    );
    if (date == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.rdvAjoute)),
    );
  }

  // ---------- Widgets ----------

  BoxDecoration _carte() {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.iconSquare),
    );
  }

  // Avatar + name + "26 ans · Femme · Groupe AB+".
  Widget _entete() {
    final infos = [
      if (_p.age != null) '${_p.age} ${AppStrings.ans}',
      if (_p.sexe != null) _p.sexe!,
      if (_p.groupeSanguin != null) '${AppStrings.groupe} ${_p.groupeSanguin}',
    ].join(' · ');

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.iconSquare,
          child: Text(
            _p.initiale,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
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
                _p.nom,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nameText,
                ),
              ),
              Text(
                infos,
                style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Red (high) or orange (medium) banner.
  Widget _bandeauAlerte() {
    final eleve = _p.alerte == NiveauAlerte.eleve;
    final couleur = eleve ? AppColors.danger : AppColors.warningText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: eleve ? AppColors.dangerBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _p.messageAlerte ?? AppStrings.alerte,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: couleur,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // The 3 tabs.
  // The 3 main tabs.
  Widget _onglets() {
    return SegmentedTabs(
      labels: const [
        AppStrings.ongletSuivi,
        AppStrings.ongletTraitements,
        AppStrings.ongletDocuments,
      ],
      selectedIndex: _onglet.index,
      onChanged: (i) => setState(() => _onglet = _Onglet.values[i]),
    );
  }

  // 7-day pain bar chart (last bar = today, red if pain >= 8).
  Widget _carteDouleur() {
    final valeurs = _p.douleur7Jours;
    final auj = DateTime.now();

    Widget graphique;
    if (valeurs.length != 7) {
      graphique = const SizedBox(
        height: 60,
        child: Center(
          child: Text(
            AppStrings.aucuneDonnee,
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
        ),
      );
    } else {
      graphique = SizedBox(
        height: 110,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final v = valeurs[i];
            final jour = DateTime(auj.year, auj.month, auj.day - (6 - i));
            final hauteur = ((v / 10) * 84).clamp(4.0, 84.0).toDouble();
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 26,
                  height: hauteur,
                  decoration: BoxDecoration(
                    color: v >= 8 ? AppColors.danger : AppColors.chartBar,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _lettres[jour.weekday - 1],
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            );
          }),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _carte(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.douleur7Jours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          graphique,
        ],
      ),
    );
  }

  // Card listing the treatments ("Plaquenil 200 mg .... 2 fois / jour").
  Widget _carteTraitements() {
    final lignes = <Widget>[];
    for (var i = 0; i < _traitements.length; i++) {
      final t = _traitements[i];
      lignes.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.medication_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.libelle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${t.foisParJour} ${AppStrings.foisParJour}',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      );
      if (i < _traitements.length - 1) {
        lignes.add(const Divider(height: 1, color: AppColors.iconSquare));
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _carte(),
      child: Column(children: lignes),
    );
  }

  // Full-width purple button.
  Widget _boutonPrincipal(String texte, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
      child: Text(
        texte,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _vide(String texte) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          texte,
          style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
      ),
    );
  }

  // One document row.
  Widget _ligneDocument(DocumentMedical d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: _carte(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.iconSquare,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.type.label} · ${_dateFr.format(d.date)}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textGrey),
        ],
      ),
    );
  }

  // Content of the selected tab.
  List<Widget> _contenuOnglet() {
    if (_chargement) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    switch (_onglet) {
      case _Onglet.suivi:
        return [
          _carteDouleur(),
          if (_traitements.isNotEmpty) ...[
            const SizedBox(height: 12),
            _carteTraitements(),
          ],
        ];

      case _Onglet.traitements:
        return [
          if (_traitements.isEmpty)
            _vide(AppStrings.aucunTraitement)
          else
            _carteTraitements(),
          const SizedBox(height: 16),
          _boutonPrincipal(AppStrings.ajouterMedicament, _ajouterTraitement),
        ];

      case _Onglet.documents:
        final affiches = _documents
            .where((d) => _filtreDoc == null || d.type == _filtreDoc)
            .toList();
        return [
          // Filter chips (scroll sideways).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SubFilterChip(
                  label: AppStrings.tout,
                  selected: _filtreDoc == null,
                  onTap: () => setState(() => _filtreDoc = null),
                ),
                for (final type in TypeDocument.values) ...[
                  const SizedBox(width: 8),
                  SubFilterChip(
                    label: type.labelPluriel,
                    selected: _filtreDoc == type,
                    onTap: () => setState(() => _filtreDoc = type),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (affiches.isEmpty)
            _vide(AppStrings.aucunDocument)
          else
            ...affiches.map(_ligneDocument),
          const SizedBox(height: 4),
          _boutonPrincipal(AppStrings.ajouterDocument, _ajouterDocument),
        ];
    }
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
                      AppStrings.fichePatient,
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

            _entete(),
            if (_p.alerte != NiveauAlerte.aucune) ...[
              const SizedBox(height: 16),
              _bandeauAlerte(),
            ],
            const SizedBox(height: 16),

            _onglets(),
            const SizedBox(height: 16),

            ..._contenuOnglet(),
            const SizedBox(height: 16),

            // "Message" and "Planifier un RDV".
            if (_onglet == _Onglet.suivi)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _ouvrirMessage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text(
                        AppStrings.message,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _planifierRdv,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: const Text(
                        AppStrings.planifierRdv,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

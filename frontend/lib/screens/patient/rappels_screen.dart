import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../features/medecin/patients/add_traitement_page.dart';
import '../../models/rendez_vous.dart';
import '../../models/traitement.dart';
import '../../providers/auth_provider.dart';
import '../../services/agenda_service.dart';
import '../../services/traitement_service.dart';
import '../../widgets/common.dart';

/// Rappels : prises du jour, rendez-vous et analyses à venir (backend).
/// Les rendez-vous et analyses sont créés par le médecin.
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

/// Document ajouté par le patient pour son médecin
class _Doc {
  final String nom;
  final int taille; // en octets
  final int onglet; // 1 = rendez-vous, 2 = analyses
  _Doc(this.nom, this.taille, this.onglet);
}

class _RappelsScreenState extends State<RappelsScreen> {
  late final TraitementService _service;
  late final AgendaService _agenda;
  int _tab = 0;
  bool _chargement = true;
  String? _erreur;
  final Set<int> _envoiEnCours = {}; // rappels en cours d'envoi « Marquer pris »

  List<_Rappel> _meds = [];
  List<_Rappel> _rdv = [];
  List<_Rappel> _analyses = [];
  final List<_Doc> _docs = [];

  @override
  void initState() {
    super.initState();
    final api = context.read<AuthProvider>().api;
    _service = TraitementService(api);
    _agenda = AgendaService(api);
    _charger();
  }

  // "Jeu 12 nov"
  static String _jour(DateTime d) =>
      cap(DateFormat('EEE d MMM', 'fr_FR').format(d).replaceAll('.', ''));

  static String _heure(DateTime d) => DateFormat('HH:mm').format(d);

  /// Prises du jour + rendez-vous + analyses à venir (créés par le médecin)
  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final r = await Future.wait([
        _service.getPrisesDuJour(),
        _agenda.getMesRendezVous(),
        _agenda.getMesAnalyses(),
      ]);
      final prises = r[0] as List<PriseDuJour>;
      final rdvs = r[1] as List<RdvPatient>;
      final analyses = r[2] as List<Analyse>;
      if (!mounted) return;
      setState(() {
        _meds = [
          for (final p in prises)
            _Rappel(p.heure, p.nom, p.dosage, pris: p.pris, rappelId: p.rappelId),
        ];
        _rdv = [
          for (final v in rdvs)
            _Rappel(
              _jour(v.dateHeure),
              v.motif,
              [v.docteur ?? v.lieu, v.medecinSpecialite, _heure(v.dateHeure)]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
            ),
        ];
        _analyses = [
          for (final a in analyses)
            _Rappel(
              _jour(a.dateHeure),
              a.type,
              [a.laboratoire, _heure(a.dateHeure)]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
            ),
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
    await _charger();
  }

  /// Choisit un document (PDF ou image) à enregistrer pour le médecin.
  /// TODO : envoyer le fichier au backend (table documents_medicaux,
  /// 04_dossiers_recherche_messages.sql) quand la route existera.
  Future<void> _addDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      if (!mounted) return;
      setState(() => _docs.add(_Doc(f.name, f.size, _tab)));
      showSnack(context, 'Document ajouté');
    } catch (_) {
      if (mounted) {
        showSnack(context, "Impossible d'ajouter le document", error: true);
      }
    }
  }

  String _taille(int octets) => octets >= 1024 * 1024
      ? '${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo'
      : '${(octets / 1024).ceil()} Ko';

  static const _messagesVides = [
    "Aucune prise de médicament prévue aujourd'hui",
    'Aucun rendez-vous à venir',
    'Aucune analyse à venir',
  ];

  @override
  Widget build(BuildContext context) {
    final list = [_meds, _rdv, _analyses][_tab];
    final mesDocs = _docs.where((d) => d.onglet == _tab).toList();
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
            if (_chargement)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erreur != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(children: [
                  Text(_erreur!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  TextButton(onPressed: _charger, child: const Text('Réessayer')),
                ]),
              )
            else if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_messagesVides[_tab],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
            if (!_chargement && _erreur == null)
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

            // Documents ajoutés pour le médecin (onglets Rendez-vous et Analyses)
            if (_tab != 0 && mesDocs.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Documents ajoutés',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final d in mesDocs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    child: Row(children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.soft,
                        child: Icon(Icons.description_outlined,
                            size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.nom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            Text('${_taille(d.taille)} · Pour le médecin',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.muted),
                        onPressed: () => setState(() => _docs.remove(d)),
                      ),
                    ]),
                  ),
                ),
            ],

            const SizedBox(height: 8),
            if (_tab == 0)
              SecondaryButton(
                label: '+ Ajouter un médicament',
                onPressed: _ajouterMedicament,
              )
            // Onglet Rendez-vous : pas de bouton, c'est le médecin qui crée les RDV
            else if (_tab == 2)
              SecondaryButton(
                label: '+ Ajouter un document',
                onPressed: _addDocument,
              ),
          ],
        ),
      ),
    );
  }
}

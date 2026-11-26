import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/document_medical.dart';
import '../../providers/auth_provider.dart';
import '../../services/dossier_service.dart';
import '../../widgets/common.dart';

/// Dossier médical : documents ajoutés par le médecin + « Partagé avec » (backend, séance 5).
class DossierScreen extends StatefulWidget {
  const DossierScreen({super.key});

  @override
  State<DossierScreen> createState() => _DossierScreenState();
}

class _DossierScreenState extends State<DossierScreen> {
  int _tab = 0;
  static const _filtres = ['Tout', 'Ordonnances', 'Analyses', 'Comptes rendus'];

  bool _chargement = true;
  String? _erreur;
  List<DocumentMedical> _docs = [];
  List<PartageDossier> _partages = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  /// GET /api/patients/me/documents + /api/patients/me/partages
  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final service = DossierService(context.read<AuthProvider>().api);
      final r = await Future.wait([
        service.getMesDocuments(),
        service.getMesPartages(),
      ]);
      if (!mounted) return;
      setState(() {
        _docs = r[0] as List<DocumentMedical>;
        _partages = r[1] as List<PartageDossier>;
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

  // Catégorie du filtre : 1 = ordonnance, 2 = analyse (+ imagerie), 3 = compte rendu
  static int _categorie(TypeDocument t) => switch (t) {
        TypeDocument.ordonnance => 1,
        TypeDocument.analyse || TypeDocument.imagerie => 2,
        TypeDocument.compteRendu => 3,
      };

  static IconData _icone(TypeDocument t) => switch (t) {
        TypeDocument.ordonnance => Icons.description_outlined,
        TypeDocument.analyse => Icons.science_outlined,
        TypeDocument.compteRendu => Icons.assignment_outlined,
        TypeDocument.imagerie => Icons.image_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final shown =
        _docs.where((d) => _tab == 0 || _categorie(d.type) == _tab).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Dossier médical')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PillTabs(
              labels: _filtres,
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
              Column(children: [
                Text(_erreur!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                TextButton(onPressed: _charger, child: const Text('Réessayer')),
              ])
            else ...[
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Aucun document',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
              for (final d in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    onTap: () => showSnack(context, 'Aperçu bientôt disponible'),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: AppColors.soft,
                        child: Icon(_icone(d.type),
                            color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.titre,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                            // "Ordonnance · 20 oct. 2026"
                            Text(
                                '${d.type.label} · '
                                '${DateFormat('d MMM y', 'fr_FR').format(d.date)}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ]),
                  ),
                ),
              const SizedBox(height: 12),
              const Text('Partagé avec',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (_partages.isEmpty)
                const Text('Votre dossier n\'est partagé avec aucun médecin',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
              for (final p in _partages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    child: Row(children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Text(
                            p.medecinNom.isEmpty
                                ? '?'
                                : p.medecinNom.trim()[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.docteur,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                            const Text('Accès autorisé',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined,
                            color: AppColors.primary, size: 18),
                        onPressed: () =>
                            showSnack(context, 'Bientôt disponible'),
                      ),
                    ]),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Ajouter un document',
              onPressed: () => showSnack(context, 'Bientôt disponible'),
            ),
          ],
        ),
      ),
    );
  }
}

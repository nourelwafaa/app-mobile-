import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/demande_suivi.dart';
import '../../providers/auth_provider.dart';
import '../../services/agenda_service.dart';
import '../../services/demandes_service.dart';
import '../../services/messages_service.dart';
import '../../services/traitement_service.dart';
import '../../widgets/common.dart';
import 'conseils_screen.dart';
import 'dossier_screen.dart';
import 'lupia_screen.dart';
import 'messages_screen.dart';
import 'rappels_screen.dart';
import 'stats_screen.dart';
import 'suivi_screen.dart';
import 'trouver_pro_screen.dart';

// Couleurs pastel (mêmes que l'accueil du médecin)
const _lavande = Color(0xFFE9DFFE);
const _rose = Color(0xFFFDE5F0);
const _menthe = Color(0xFFE7F7F4);
const _iconLavande = Color(0xFF7B5CE6);
const _iconRose = Color(0xFFE0526F);
const _iconMenthe = Color(0xFF2EAD8A);
const _rond = Color(0xFFD4ACFC);
const _titre = Color(0xFF4B1D66);
const _gris = Color(0xFF655D70);

/// Accueil patient. Design de la binôme ; données du backend :
/// icône Messages (non lus), demandes de suivi des médecins,
/// prochaine prise et prochain rendez-vous dans la carte « Rappels et rendez-vous ».
class HomeScreen extends StatelessWidget {
  /// Optionnel : permet d'ouvrir l'onglet « Rapports » depuis la carte
  /// « Rappels et rendez-vous » (voir main_shell.dart).
  final VoidCallback? onOpenRappels;

  const HomeScreen({super.key, this.onOpenRappels});

  void _go(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final prenom = context.watch<AuthProvider>().user?.prenom ?? '';

    return SafeArea(
      child: Stack(
        children: [
          // Grand papillon pâle en haut à droite (décoration)
          Positioned(
            top: 60,
            right: -30,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: Image.asset('assets/images/lupus_logo.png', width: 190),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // ---- En-tête ----
              Row(
                children: [
                  Image.asset('assets/images/lupus_logo.png', height: 44),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lupus+',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      Text('Espace patient',
                          style: TextStyle(fontSize: 12, color: _gris)),
                    ],
                  ),
                  const Spacer(),
                  // Messages avec ses médecins (séance 7), point rouge si non lus
                  const _IconeMessages(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        size: 26, color: AppColors.primary),
                    onPressed: () => showSnack(context, 'Aucune notification'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                prenom.isEmpty ? 'Bonjour' : 'Bonjour, $prenom',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: _titre),
              ),
              const SizedBox(height: 4),
              const Text("Prenez soin de vous aujourd'hui",
                  style: TextStyle(fontSize: 13, color: _gris)),
              const SizedBox(height: 22),

              // Demandes de suivi des médecins (consentement), visible seulement s'il y en a
              const _DemandesSuivi(),

              // ---- Carte violette : suivi du jour ----
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Comment vous sentez-vous aujourd'hui ?",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.3)),
                    const SizedBox(height: 6),
                    const Text(
                        'Prenez une minute pour noter votre douleur, '
                        'votre fatigue et votre humeur.',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.5)),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => _go(context, const SuiviScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      child: const Text('Faire mon suivi du jour',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---- Titre de section ----
              const Row(
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Mon espace',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B1B3F))),
                ],
              ),
              const SizedBox(height: 12),

              // ---- 6 cartes pastel en 2 colonnes ----
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // Baisse cette valeur (ex. 1.15) si le texte déborde
                childAspectRatio: 1.3,
                children: [
                  _NavCard(
                    couleur: _rose,
                    iconColor: _iconRose,
                    icon: Icons.edit_note,
                    titre: 'Suivi du jour',
                    sousTitre: 'Notez vos symptômes',
                    onTap: () => _go(context, const SuiviScreen()),
                  ),
                  _NavCard(
                    couleur: _menthe,
                    iconColor: _iconMenthe,
                    icon: Icons.bar_chart,
                    titre: 'Mes statistiques',
                    sousTitre: 'Voir mon évolution',
                    onTap: () => _go(context, const StatsScreen()),
                  ),
                  _NavCard(
                    couleur: _lavande,
                    iconColor: _iconLavande,
                    icon: Icons.folder_open,
                    titre: 'Dossier médical',
                    sousTitre: 'Mes documents',
                    onTap: () => _go(context, const DossierScreen()),
                  ),
                  _NavCard(
                    couleur: _lavande,
                    iconColor: _iconLavande,
                    icon: Icons.location_on_outlined,
                    titre: 'Trouver un pro',
                    sousTitre: 'Médecins près de moi',
                    onTap: () => _go(context, const TrouverProScreen()),
                  ),
                  _NavCard(
                    couleur: _menthe,
                    iconColor: _iconMenthe,
                    icon: Icons.auto_awesome,
                    titre: 'LupIA',
                    sousTitre: 'Votre assistante',
                    onTap: () => _go(context, const LupiaScreen()),
                  ),
                  _NavCard(
                    couleur: _rose,
                    iconColor: _iconRose,
                    icon: Icons.lightbulb_outline,
                    titre: 'Conseils',
                    sousTitre: 'Astuces au quotidien',
                    onTap: () => _go(context, const ConseilsScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Carte « Rappels et rendez-vous » ----
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onOpenRappels != null
                      ? onOpenRappels!()
                      : _go(context, const RappelsScreen()),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _rond,
                          child: Icon(Icons.calendar_month,
                              size: 20, color: AppColors.primary),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rappels et rendez-vous',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2B1B3F))),
                              // Prochaine prise + prochain RDV (backend)
                              _ResumeRappels(),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: _gris),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte pastel de l'accueil : icône + titre + courte phrase.
class _NavCard extends StatelessWidget {
  final Color couleur;
  final Color iconColor;
  final IconData icon;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;

  const _NavCard({
    required this.couleur,
    required this.iconColor,
    required this.icon,
    required this.titre,
    required this.sousTitre,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: couleur,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(180),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B1B3F))),
                const SizedBox(height: 2),
                Text(sousTitre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _gris)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Sous-titre de la carte « Rappels et rendez-vous » :
/// prochaine prise du jour (GET /api/patients/me/prises/aujourdhui)
/// et prochain rendez-vous (GET /api/patients/me/rendez-vous).
/// Tant que rien n'est chargé : le texte de la binôme.
class _ResumeRappels extends StatefulWidget {
  const _ResumeRappels();

  @override
  State<_ResumeRappels> createState() => _ResumeRappelsState();
}

class _ResumeRappelsState extends State<_ResumeRappels> {
  String? _prise;
  String? _rdv;

  @override
  void initState() {
    super.initState();
    _chargerPrise();
    _chargerRdv();
  }

  Future<void> _chargerPrise() async {
    try {
      final prises = await TraitementService(context.read<AuthProvider>().api)
          .getPrisesDuJour();
      final aFaire = prises.where((p) => !p.pris);
      String? texte;
      if (prises.isNotEmpty && aFaire.isEmpty) {
        texte = 'Toutes les prises du jour sont faites';
      } else if (aFaire.isNotEmpty) {
        final p = aFaire.first;
        texte = '${p.nom} ${p.dosage} · ${p.heure}';
      }
      if (mounted) setState(() => _prise = texte);
    } catch (_) {
      // On garde le texte fixe si le serveur ne répond pas.
    }
  }

  Future<void> _chargerRdv() async {
    try {
      final rdvs = await AgendaService(context.read<AuthProvider>().api)
          .getMesRendezVous();
      if (rdvs.isEmpty) return;
      final r = rdvs.first; // déjà trié du plus proche au plus lointain
      final titre =
          r.docteur != null ? 'RDV avec ${r.docteur}' : 'RDV : ${r.motif}';
      // "Jeudi 12 nov · 10:30"
      final quand =
          '${cap(DateFormat('EEEE d MMM', 'fr_FR').format(r.dateHeure).replaceAll('.', ''))}'
          ' · ${DateFormat('HH:mm').format(r.dateHeure)}';
      if (mounted) setState(() => _rdv = '$titre, $quand');
    } catch (_) {
      // On garde le texte fixe si le serveur ne répond pas.
    }
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, color: _gris);
    if (_prise == null && _rdv == null) {
      return const Text('Médicaments, consultations, analyses', style: style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_prise != null)
          Text(_prise!,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        if (_rdv != null)
          Text(_rdv!,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
      ],
    );
  }
}

/// Icône « Messages » de l'accueil patient (séance 7), même design que chez le médecin :
/// point rouge s'il y a des messages non lus. Ouvre « Messages » (ses médecins).
class _IconeMessages extends StatefulWidget {
  const _IconeMessages();

  @override
  State<_IconeMessages> createState() => _IconeMessagesState();
}

class _IconeMessagesState extends State<_IconeMessages> {
  static const Color _rouge = Color(0xFFD4246B); // même rouge que chez le médecin
  bool _nonLus = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  /// GET /api/patients/me/medecins → total des non-lus
  Future<void> _charger() async {
    try {
      final n = await MessagesService(context.read<AuthProvider>().api)
          .nombreNonLusPatient();
      if (mounted) setState(() => _nonLus = n > 0);
    } catch (_) {
      // Pas de point rouge si le serveur ne répond pas.
    }
  }

  Future<void> _ouvrir() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const MessagesScreen()),
    );
    await _charger(); // les messages lus ne comptent plus
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _ouvrir,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 24, color: AppColors.primary),
          if (_nonLus)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _rouge,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bandeau « demande de suivi » de l'accueil patient (consentement) :
/// un médecin ne voit le dossier qu'après « Accepter ». Rien n'est affiché s'il n'y a pas de demande.
class _DemandesSuivi extends StatefulWidget {
  const _DemandesSuivi();

  @override
  State<_DemandesSuivi> createState() => _DemandesSuiviState();
}

class _DemandesSuiviState extends State<_DemandesSuivi> {
  late final DemandesService _service;
  List<DemandeSuivi> _demandes = [];
  final Set<int> _envoi = {}; // demandes en cours de réponse

  @override
  void initState() {
    super.initState();
    _service = DemandesService(context.read<AuthProvider>().api);
    _charger();
  }

  /// GET /api/patients/me/demandes
  Future<void> _charger() async {
    try {
      final liste = await _service.getDemandes();
      if (mounted) setState(() => _demandes = liste);
    } catch (_) {
      // Pas de bandeau si le serveur ne répond pas.
    }
  }

  /// PUT /api/patients/me/demandes/:id
  Future<void> _repondre(DemandeSuivi d, bool accepter) async {
    if (!accepter) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Refuser la demande ?'),
          content: Text('${d.docteur} ne pourra pas voir votre dossier médical.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Refuser')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _envoi.add(d.id));
    try {
      final message = await _service.repondre(d.id, accepter: accepter);
      if (!mounted) return;
      showSnack(context, message);
      setState(() => _demandes.removeWhere((x) => x.id == d.id));
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _envoi.remove(d.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_demandes.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final d in _demandes)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.soft,
                      child: Icon(Icons.person_add_alt_1,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${d.docteur} souhaite vous suivre',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          if ((d.specialite ?? '').isNotEmpty)
                            Text(d.specialite!,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'En acceptant, ce médecin pourra voir votre dossier médical, '
                    'vos suivis et vos traitements, et vous écrire.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _envoi.contains(d.id)
                            ? null
                            : () => _repondre(d, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.border),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Refuser'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _envoi.contains(d.id)
                            ? null
                            : () => _repondre(d, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Accepter'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

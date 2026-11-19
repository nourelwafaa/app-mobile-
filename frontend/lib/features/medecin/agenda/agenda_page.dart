import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/features/medecin/agenda/new_rdv_page.dart';
import 'package:lupus_plus/models/rendez_vous.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// The doctor's agenda: a week strip + the appointments of the selected day.
class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  // Page number of the current week in the week strip.
  static const int _pageDepart = 1000;
  static const List<String> _lettres = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  final MedecinService _service = MedecinService();
  late final PageController _pageController;
  late final DateTime _aujourdhui; // today (date only)
  late DateTime _selection; // selected day

  List<RendezVous> _rdvs = [];
  bool _chargement = true;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _aujourdhui = DateTime(now.year, now.month, now.day);
    _selection = _aujourdhui;
    _pageController = PageController(initialPage: _pageDepart);
    _charger();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Loads (or reloads) the appointments.
  Future<void> _charger() async {
    try {
      final liste = await _service.getRendezVous();
      if (!mounted) return;
      setState(() {
        _rdvs = liste;
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

  // ---------- Small helpers ----------

  // Monday of the week shown on a given page.
  DateTime _lundi(int page) {
    final jour = _aujourdhui.day -
        (_aujourdhui.weekday - 1) +
        (page - _pageDepart) * 7;
    return DateTime(_aujourdhui.year, _aujourdhui.month, jour);
  }

  bool _memeJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Appointments of one day, sorted by time.
  List<RendezVous> _rdvsDuJour(DateTime jour) {
    final liste = _rdvs.where((r) => _memeJour(r.dateHeure, jour)).toList();
    liste.sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
    return liste;
  }

  // First letter in capital ("jeudi" -> "Jeudi").
  String _maj(String texte) =>
      texte.isEmpty ? texte : texte[0].toUpperCase() + texte.substring(1);

  // "09:05"
  String _heure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // When the week changes, the selection moves to the same weekday.
  void _surChangementSemaine(int page) {
    final lundi = _lundi(page);
    setState(() {
      _selection = DateTime(
        lundi.year,
        lundi.month,
        lundi.day + (_selection.weekday - 1),
      );
    });
  }

  // ---------- Actions ----------

  // Bottom sheet to finish or cancel a planned appointment.
  Future<void> _ouvrirActions(RendezVous r) async {
    if (r.statut != StatutRdv.planifie) return; // nothing to do otherwise

    final choix = await showModalBottomSheet<StatutRdv>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.successText,
                ),
                title: const Text(AppStrings.marquerTermine),
                onTap: () => Navigator.pop(sheetContext, StatutRdv.termine),
              ),
              ListTile(
                leading: const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.danger,
                ),
                title: const Text(
                  AppStrings.annulerRdv,
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () => Navigator.pop(sheetContext, StatutRdv.annule),
              ),
            ],
          ),
        );
      },
    );

    if (choix == null) return;
    await _service.updateStatutRdv(r.id, choix);
    await _charger();
  }

  // Opens the "new appointment" page, then shows the day of the new one.
  Future<void> _nouveauRdv() async {
    final patients = await _service.getPatients();
    if (!mounted) return;

    final date = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (_) => NewRdvPage(patients: patients, dateInitiale: _selection),
      ),
    );
    if (date == null || !mounted) return;

    await _charger();
    if (!mounted) return;

    // Select the new appointment's day and jump to its week.
    final jour = DateTime(date.year, date.month, date.day);
    final lundiJour = DateTime(jour.year, jour.month, jour.day - (jour.weekday - 1));
    final lundiAuj = DateTime(
      _aujourdhui.year,
      _aujourdhui.month,
      _aujourdhui.day - (_aujourdhui.weekday - 1),
    );
    final semaines = (lundiJour.difference(lundiAuj).inDays / 7).round();
    final page = _pageDepart + semaines;

    setState(() => _selection = jour);
    if (page >= 0 && _pageController.hasClients) {
      _pageController.jumpToPage(page);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.rdvAjoute)),
    );
  }

  // ---------- Widgets ----------

  // One day of the week strip (letter, number, dot).
  Widget _celluleJour(DateTime jour, int index) {
    final estSelectionne = _memeJour(jour, _selection);
    final aDesRdv = _rdvs.any((r) => _memeJour(r.dateHeure, jour));

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selection = jour),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: estSelectionne ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _lettres[index],
                style: TextStyle(
                  fontSize: 12,
                  color: estSelectionne ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${jour.day}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: estSelectionne ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              // Dot if the day has appointments (empty space otherwise).
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: aDesRdv
                      ? (estSelectionne ? Colors.white : AppColors.primary)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Colored status label (Terminé / Planifié / Annulé).
  Widget _chip(StatutRdv statut) {
    String texte;
    Color fond;
    Color couleur;
    switch (statut) {
      case StatutRdv.termine:
        texte = AppStrings.statutTermine;
        fond = AppColors.successBg;
        couleur = AppColors.successText;
        break;
      case StatutRdv.planifie:
        texte = AppStrings.statutPlanifie;
        fond = AppColors.iconSquare;
        couleur = AppColors.primary;
        break;
      case StatutRdv.annule:
        texte = AppStrings.statutAnnule;
        fond = AppColors.dangerBg;
        couleur = AppColors.danger;
        break;
    }
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

  // One line: time on the left + appointment card.
  Widget _ligneRdv(RendezVous r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              _heure(r.dateHeure),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _ouvrirActions(r),
              child: Container(
                // Clips the purple left bar to the rounded corners.
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.iconSquare),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Purple bar on the left.
                      Container(width: 4, color: AppColors.primary),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.iconSquare,
                                child: Text(
                                  r.patientNom[0].toUpperCase(),
                                  style: const TextStyle(
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
                                      r.patientNom,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      r.motif,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _chip(r.statut),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // The list part: spinner, error, empty message or the appointments.
  List<Widget> _contenu(List<RendezVous> duJour) {
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
    if (duJour.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              AppStrings.aucunRdv,
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          ),
        ),
      ];
    }
    return duJour.map(_ligneRdv).toList();
  }

  @override
  Widget build(BuildContext context) {
    final duJour = _rdvsDuJour(_selection);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // Page title.
          const Center(
            child: Text(
              AppStrings.navAgenda,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // "Novembre 2026"
          Text(
            _maj(DateFormat('MMMM yyyy', 'fr_FR').format(_selection)),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          // Week strip: swipe left/right to change week.
          SizedBox(
            height: 84,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _surChangementSemaine,
              itemBuilder: (context, page) {
                final lundi = _lundi(page);
                return Row(
                  children: List.generate(7, (i) {
                    final jour = DateTime(lundi.year, lundi.month, lundi.day + i);
                    return _celluleJour(jour, i);
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // "Jeudi 12 novembre" ........ "3 rendez-vous"
          Row(
            children: [
              Text(
                _maj(DateFormat('EEEE d MMMM', 'fr_FR').format(_selection)),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (duJour.isNotEmpty)
                Text(
                  '${duJour.length} ${AppStrings.rendezVous}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          ..._contenu(duJour),
          const SizedBox(height: 8),

          // "+ Nouveau rendez-vous" button.
          ElevatedButton(
            onPressed: _nouveauRdv,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: const Text(
              AppStrings.nouveauRendezVous,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
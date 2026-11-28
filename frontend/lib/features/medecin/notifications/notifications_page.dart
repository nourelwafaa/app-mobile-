import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/date_format.dart';
import 'package:lupus_plus/features/medecin/alerts/alertes_page.dart';
import 'package:lupus_plus/features/medecin/messages/chat_page.dart';
import 'package:lupus_plus/models/notification_medecin.dart';
import 'package:lupus_plus/models/patient.dart';
import 'package:lupus_plus/providers/auth_provider.dart';
import 'package:lupus_plus/services/espace_medecin_service.dart';
import 'package:lupus_plus/services/medecin_service.dart';
import 'package:provider/provider.dart';

// The notifications page, grouped by day.
class NotificationsPage extends StatefulWidget {
  // Opens the Agenda tab on a given day (provided by the shell).
  final ValueChanged<DateTime> onOuvrirAgenda;

  const NotificationsPage({super.key, required this.onOuvrirAgenda});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final EspaceMedecinService _service; // backend (séance 8)

  List<NotificationMedecin> _notifications = [];
  bool _chargement = true;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _service = EspaceMedecinService(context.read<AuthProvider>().api);
    _charger();
    // Reload when a notification is read.
    MedecinService.notificationsChanged.addListener(_charger);
  }

  @override
  void dispose() {
    MedecinService.notificationsChanged.removeListener(_charger);
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final liste = await _service.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = liste;
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

  // Tap on a row: marks it read, then opens what it is about.
  Future<void> _ouvrir(NotificationMedecin n) async {
    if (!n.lu) {
      try {
        await _service.marquerNotificationLue(n.id);
        setState(() => n.lu = true);
        // Recharge le point de la cloche sur l'accueil
        MedecinService.notificationsChanged.value++;
      } catch (_) {
        // Pas grave : on ouvre quand même ce qui est concerné.
      }
    }
    if (!mounted) return;

    switch (n.type) {
      case TypeNotification.message:
        final id = n.patientId;
        if (id == null) return;
        final patient = await _service.getPatient(id);
        if (patient == null || !mounted) return;
        // Full screen, like the chat opened from the messages list.
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => ChatPage(patient: patient)),
        );
      case TypeNotification.alerte:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AlertesPage()),
        );
      case TypeNotification.rendezVous:
        final jour = n.rdvDate ?? DateTime.now();
        // Back to the Accueil first, so it is clean when the doctor returns.
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onOuvrirAgenda(jour);
    }
  }

  // « Tout marquer comme lu »
  Future<void> _toutMarquerLu() async {
    try {
      await _service.marquerToutesLues();
      // La page et le point de la cloche se rechargent.
      MedecinService.notificationsChanged.value++;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.erreurChargement)),
      );
    }
  }

  // Icon of a notification.
  IconData _icone(NotificationMedecin n) => switch (n.type) {
        TypeNotification.message => Icons.chat_bubble_outline,
        TypeNotification.alerte => Icons.warning_amber_rounded,
        TypeNotification.rendezVous => Icons.calendar_today_outlined,
      };

  // Icon color: alerts follow their level, others are purple.
  Color _couleurIcone(NotificationMedecin n) {
    if (n.type != TypeNotification.alerte) return AppColors.primary;
    return switch (n.niveau) {
      NiveauAlerte.eleve => AppColors.danger,
      NiveauAlerte.moyen => AppColors.warningText,
      _ => AppColors.infoText,
    };
  }

  // One notification row.
  Widget _ligne(NotificationMedecin n) {
    final nonLu = !n.lu;
    // Today and yesterday show the time, older ones show "Lun." or "17/11".
    final recent = formatGroupeNotification(n.date) != AppStrings.plusAncien;
    final heure = recent ? formatHeure(n.date) : formatHeureListe(n.date);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _ouvrir(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        // Unread: white card. Read: flat with a line under it.
        decoration: nonLu
            ? BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.iconSquare),
              )
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.iconSquare)),
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lilac square with the icon.
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.iconSquare,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icone(n), size: 22, color: _couleurIcone(n)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.titre,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: nonLu ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  heure,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
                if (nonLu) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Group title ("Aujourd'hui", "Hier", "Plus ancien").
  Widget _titreGroupe(String texte) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Text(
        texte,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  // Spinner, error, empty message, or the grouped rows.
  List<Widget> _contenu() {
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
    if (_notifications.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              AppStrings.aucuneNotification,
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    String? dernierGroupe;
    for (final n in _notifications) {
      final groupe = formatGroupeNotification(n.date);
      if (groupe != dernierGroupe) {
        widgets.add(_titreGroupe(groupe));
        dernierGroupe = groupe;
      }
      widgets.add(_ligne(n));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final aDesNonLues = _notifications.any((n) => !n.lu);

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
                      AppStrings.notifications,
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

            // "Tout marquer comme lu" (only while something is unread).
            if (aDesNonLues)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _toutMarquerLu,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      AppStrings.toutMarquerLu,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),

            ..._contenu(),
          ],
        ),
      ),
    );
  }
}
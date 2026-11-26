import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/name_utils.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// Top of the home page: logo, app name, message and bell icons, greeting.
class HomeHeader extends StatelessWidget {
  final String nomMedecin; // e.g. "Martin"
  final bool messagesNonLus; // point rouge sur l'icône Messages (GET /api/medecin/accueil)
  final VoidCallback? onMessages; // tap on the message icon
  final VoidCallback? onNotifications; // tap on the bell (no page yet)

  const HomeHeader({
    super.key,
    required this.nomMedecin,
    this.messagesNonLus = false,
    this.onMessages,
    this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: logo + names on the left, icons on the right.
        Row(
          children: [
            Image.asset('assets/images/lupus_logo.png', height: 44),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  AppStrings.espaceMedecin,
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
            const Spacer(),
            // The red dot appears only when there are unread messages.
            _IconeAvecPastille(
              icon: Icons.chat_bubble_outline,
              afficherPastille: messagesNonLus,
              onTap: onMessages,
            ),
           // The red dot appears only when there are unread notifications.
            ValueListenableBuilder<int>(
              valueListenable: MedecinService.notificationsChanged,
              builder: (context, value, child) => _IconeAvecPastille(
                icon: Icons.notifications_none,
                afficherPastille:
                    MedecinService().nombreNotificationsNonLues() > 0,
                onTap: onNotifications,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Line 2: "Bonjour Dr Martin"
        Text(
          '${AppStrings.bonjour} ${nomAvecTitre(nomMedecin)}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.nameText,
          ),
        ),
        const SizedBox(height: 4),
        // Line 3: subtitle.
        const Text(
          AppStrings.apercu,
          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

// An icon button with an optional red dot at its top-right corner.
class _IconeAvecPastille extends StatelessWidget {
  final IconData icon;
  final bool afficherPastille;
  final VoidCallback? onTap;

  const _IconeAvecPastille({
    required this.icon,
    required this.afficherPastille,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 26, color: AppColors.primary),
          if (afficherPastille)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.notifDot,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
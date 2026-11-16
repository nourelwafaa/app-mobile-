import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';

// Top of the home page: logo, app name, avatar and greeting.
class HomeHeader extends StatelessWidget {
  final String nomMedecin; // e.g. "Dr. Martin"

  const HomeHeader({super.key, required this.nomMedecin});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: logo + names on the left, avatar on the right.
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
            // Pushes the avatar to the far right.
            const Spacer(),
            // Placeholder avatar (no real photo until the profile exists).
            const CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.avatarCircle,
              child: Icon(Icons.person, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Line 2: "Bonjour Dr. Martin 👋"
        Text(
          '${AppStrings.bonjour} $nomMedecin 👋',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
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
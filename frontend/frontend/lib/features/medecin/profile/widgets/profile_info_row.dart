import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';

// One row of the profile card: icon in a square + small label + value.
// If the value is empty, it shows "Non renseigné" in grey.
class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label; // e.g. "Spécialité"
  final String? value; // can be null or empty
  final bool showDivider; // line under the row (false for the last one)

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    // The text to display, or null if the value is missing or blank.
    final String? texte =
        (value == null || value!.trim().isEmpty) ? null : value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Rounded lilac square holding the icon.
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.iconSquare,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 14),

              // Label above the value. Expanded lets long text wrap
              // instead of overflowing.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      texte ?? AppStrings.nonRenseigne,
                      style: TextStyle(
                        fontSize: 14,
                        // Normal weight and grey when empty.
                        fontWeight:
                            texte == null ? FontWeight.w400 : FontWeight.w600,
                        color: texte == null
                            ? AppColors.textGrey
                            : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Thin line under the row, starting after the icon (36 + 14 = 50).
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 50),
            child: Divider(height: 1, color: AppColors.iconSquare),
          ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';

// One colored counter card (e.g. icon + "24" + "Patients suivis").
class StatCard extends StatelessWidget {
  final IconData icon; // icon shown on the left of the number
  final Color iconColor;
  final Color backgroundColor;
  final String value; // the number, as text (e.g. "24" or "+12%")
  final String label; // the small text under the number

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Space between the card edge and its content.
      padding: const EdgeInsets.all(14),
      // Rounded colored background.
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + number on the same line.
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Label under the number (max 2 lines).
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/date_format.dart';
import 'package:lupus_plus/models/patient.dart';

// One row of the "recent patients" list (flat, with a divider line).
class PatientTile extends StatelessWidget {
  final Patient patient;
  final VoidCallback? onTap; // tap on the row

  const PatientTile({super.key, required this.patient, this.onTap});

  // Small "Alerte" label (red = high, orange = medium).
  Widget _chipAlerte() {
    final eleve = patient.alerte == NiveauAlerte.eleve;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: eleve ? AppColors.dangerBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppStrings.alerte,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: eleve ? AppColors.danger : AppColors.warningText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          // Colored circle with the first letter of the name.
          leading: CircleAvatar(
            backgroundColor: AppColors.avatarCircle,
            child: Text(
              patient.initiale,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Text(
            patient.nom,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          // "Dernière activité : aujourd'hui, 09:12"
          subtitle: Text(
            '${AppStrings.derniereActivite} : ${formatSuivi(patient.derniereActivite)}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
          ),
          // "Alerte" label (if any) + arrow.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (patient.alerte != NiveauAlerte.aucune) ...[
                _chipAlerte(),
                const SizedBox(width: 6),
              ],
              const Icon(Icons.chevron_right, color: AppColors.textGrey),
            ],
          ),
          // Tap on the row: handled by the page that shows the list.
          onTap: onTap,
        ),
        const Divider(height: 1, color: AppColors.iconSquare),
      ],
    );
  }
}
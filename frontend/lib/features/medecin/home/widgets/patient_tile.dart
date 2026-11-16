import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/date_format.dart';
import 'package:lupus_plus/models/patient.dart';

// One row of the "recent patients" list.
class PatientTile extends StatelessWidget {
  final Patient patient;

  const PatientTile({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Removes the default side padding so the text has more room.
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
      // Patient name.
      title: Text(
        patient.nom,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      // "Dernière activité : Aujourd'hui, 09:12"
      subtitle: Text(
        '${AppStrings.derniereActivite} : ${formatActivite(patient.derniereActivite)}',
        style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
      ),
      // Arrow on the right.
      trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
      // No onTap yet: nothing happens until the patient pages exist.
    );
  }
}
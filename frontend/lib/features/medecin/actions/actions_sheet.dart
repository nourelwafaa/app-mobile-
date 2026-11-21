import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';

// The 5 quick actions.
enum ActionRapide {
  ajouterPatient,
  nouveauRdv,
  prescrireTraitement,
  ajouterCompteRendu,
  envoyerMessage,
}

// Opens the sheet and returns the chosen action (null if it was just closed).
Future<ActionRapide?> showActionsRapides(BuildContext context) {
  return showModalBottomSheet<ActionRapide>(
    context: context,
    useRootNavigator: true, // covers the whole screen, bottom bar included
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _ActionsSheet(),
  );
}

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet();

  // One action card: icon square + title + subtitle + arrow.
  Widget _carte(
    BuildContext context,
    ActionRapide action,
    IconData icon,
    String titre,
    String sousTitre,
  ) {
    return GestureDetector(
      // Closes the sheet and returns the chosen action.
      onTap: () => Navigator.pop(context, action),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.iconSquare),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.iconSquare,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sousTitre,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Small grey handle.
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8CCE3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              AppStrings.queFaire,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.nameText,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              AppStrings.actionsRapides,
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            const SizedBox(height: 16),

            _carte(
              context,
              ActionRapide.ajouterPatient,
              Icons.people_outline,
              AppStrings.actionAjouterPatient,
              AppStrings.actionAjouterPatientSous,
            ),
            _carte(
              context,
              ActionRapide.nouveauRdv,
              Icons.calendar_today_outlined,
              AppStrings.nouveauRdvTitre,
              AppStrings.actionRdvSous,
            ),
            _carte(
              context,
              ActionRapide.prescrireTraitement,
              Icons.medication_outlined,
              AppStrings.actionPrescrire,
              AppStrings.actionPrescrireSous,
            ),
            _carte(
              context,
              ActionRapide.ajouterCompteRendu,
              Icons.description_outlined,
              AppStrings.actionCompteRendu,
              AppStrings.actionCompteRenduSous,
            ),
            _carte(
              context,
              ActionRapide.envoyerMessage,
              Icons.chat_bubble_outline,
              AppStrings.actionMessage,
              AppStrings.actionMessageSous,
            ),
            const SizedBox(height: 8),

            // "×" button, at the same place as the "+" of the bottom bar.
            Center(
              child: Material(
                color: AppColors.accent,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
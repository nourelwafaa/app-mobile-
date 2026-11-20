import 'package:flutter/material.dart';
import 'package:lupus_plus/features/medecin/patients/patients_page.dart';

// Own navigator for the Patients tab: the bottom bar stays visible
// on the list and on the patient file.
class PatientsNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onRetourAccueil; // back arrow of the list

  const PatientsNavigator({
    super.key,
    required this.navigatorKey,
    required this.onRetourAccueil,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PatientsPage(onRetour: onRetourAccueil),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:lupus_plus/features/medecin/home/home_page.dart';

// Own navigator for the Accueil tab: the bottom bar stays visible
// on the conversations list.
class AccueilNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onVoirTout; // "Voir tout": opens the Patients tab

  const AccueilNavigator({
    super.key,
    required this.navigatorKey,
    required this.onVoirTout,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomePage(onVoirTout: onVoirTout),
        );
      },
    );
  }
}
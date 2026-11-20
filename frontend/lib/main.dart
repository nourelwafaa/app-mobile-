import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'features/medecin/shell/medecin_shell.dart';
import 'screens/patient/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final auth = AuthProvider();
  await auth.init();
  runApp(ChangeNotifierProvider.value(value: auth, child: const LupusApp()));
}

class LupusApp extends StatelessWidget {
  const LupusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lupus+',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

/// Affiche l'écran adapté selon l'état de connexion.
/// Après login / logout, il suffit de revenir à cet écran (popUntil first).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unauthenticated:
        return const WelcomeScreen();
      case AuthStatus.authenticated:
        return auth.user?.role == 'medecin'
            ? const MedecinShell()
            : const MainShell();
    }
  }
}

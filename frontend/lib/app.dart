import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_theme.dart';
import 'package:lupus_plus/features/medecin/shell/medecin_shell.dart';

// Root widget of the app: sets the title, the theme and the first screen.
class LupusApp extends StatelessWidget {
  const LupusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App name.
      title: AppStrings.appName,

      // Hides the red "DEBUG" ribbon.
      debugShowCheckedModeBanner: false,

      // Our theme from app_theme.dart.
      theme: AppTheme.light,

      // First screen: the doctor's space (login comes later).
      home: const MedecinShell(),
    );
  }
}
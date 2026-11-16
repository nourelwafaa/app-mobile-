import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const LupusApp());
}

class LupusApp extends StatelessWidget {
  const LupusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lupus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const OnboardingScreen(),
    );
  }
}

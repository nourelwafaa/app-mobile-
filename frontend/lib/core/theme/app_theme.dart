import 'package:flutter/material.dart';
import 'app_colors.dart';

// Defines the look of the whole app (font + colors) in one place.
class AppTheme {
  // The light theme used by the app.
  static ThemeData get light {
    return ThemeData(
      // Modern Material look.
      useMaterial3: true,

      // Font registered in pubspec.yaml.
      fontFamily: 'Poppins',

      // Background color of every page.
      scaffoldBackgroundColor: AppColors.background,

      // Builds the other colors (buttons, etc.) from our main purple.
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    );
  }
}
import 'package:flutter/material.dart';

class AppTheme {
  static const purple = Color(0xFF78328D);
  static const darkPurple = Color(0xFF68277D);
  static const palePurple = Color(0xFFF7F0FA);
  static const grey = Color(0xFF7E8791);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: purple,
      primary: purple,
      secondary: darkPurple,
      surface: Colors.white,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: purple,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3EAF6),
      hintStyle: const TextStyle(color: grey, fontSize: 13),
      prefixIconColor: purple,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

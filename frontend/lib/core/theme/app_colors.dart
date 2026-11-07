import 'package:flutter/material.dart';

// All the colors of the app in one place.
// Color(0xFF......) = opaque color, the 6 digits are the hex code without "#".
class AppColors {
  // Main colors
  static const Color primary = Color(0xFF6B3590); // main purple (titles, links)
  static const Color accent = Color(0xFF883FBC);  // center "+" button

  // Backgrounds
  static const Color background = Color(0xFFF9EDFE); // page background
  static const Color navBar = Color(0xFFFBF5FE);     // bottom bar background

  // Counter cards on the home page
  static const Color cardPatients = Color(0xFFE9DFFE);
  static const Color cardRdv = Color(0xFFE9DFFE);
  static const Color cardAlertes = Color(0xFFFDE5F0);
  static const Color cardAmelioration = Color(0xFFE7F7F4);

  // Icons inside the counter cards (estimated by eye)
  static const Color iconPatients = Color(0xFF7B5CE6);
  static const Color iconAlertes = Color(0xFFE0526F);
  static const Color iconRdv = Color(0xFF7B5CE6);
  static const Color iconAmelioration = Color(0xFF2EAD8A);

  // Patient rows
  static const Color avatarCircle = Color(0xFFD4ACFC); // circle with the initial

  // Texts
  static const Color textDark = Color(0xFF2B1B3F); // numbers and names
  static const Color textGrey = Color(0xFF7A7285); // small labels
}
import 'package:flutter/material.dart';

// All the colors of the app in one place.
// Color(0xFF......) = opaque color, the 6 digits are the hex code without "#".
class AppColors {
  // Main colors
  static const Color primary = Color(0xFF6A2C8E); // main purple (measured) // main purple (titles, links)
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

  // Profile page
  static const Color card = Color(0xFFFFFFFF);       // white card
  static const Color iconSquare = Color(0xFFEFE5F7); // square behind icons + divider lines
  static const Color nameText = Color(0xFF4B1D66);   // doctor's name
  static const Color danger = Color(0xFFB42318);     // red "Se déconnecter"
  static const Color dangerLight = Color(0xFFE0665C); // light red (email note)

  // Agenda
  static const Color successBg = Color(0xFFE3F5EC);   // "Terminé" chip background
  static const Color successText = Color(0xFF1E7B4A); // "Terminé" chip text
  static const Color dangerBg = Color(0xFFFDE5E3);    // "Annulé" chip background

  // Patients
  static const Color warningBg = Color(0xFFFFF1DC);   // orange alert background
  static const Color warningText = Color(0xFFB26A00); // orange alert text
  static const Color chartBar = Color(0xFFB98FD6);    // pain chart bars

  // Messages
  static const Color notifDot = Color(0xFFD4246B);     // red dot on the message icon
  static const Color sendDisabled = Color(0xFFC4A3DA); // send button when the box is empty

  // Low-level alert (blue label)
  static const Color infoBg = Color(0xFFE4ECFA);
  static const Color infoText = Color(0xFF1F4E99);
}
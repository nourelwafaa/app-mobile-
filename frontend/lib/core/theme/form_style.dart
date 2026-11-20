import 'package:flutter/material.dart';
import 'app_colors.dart';

// Shared look of the forms (same as the edit profile page).

OutlineInputBorder _bordure(Color couleur) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: couleur),
  );
}

// Style of the text typed in a field.
const TextStyle formTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: AppColors.textDark,
);

// White rounded field with an icon and a purple label.
InputDecoration formDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 17, color: AppColors.primary),
    floatingLabelStyle: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      color: AppColors.primary,
    ),
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: AppColors.card,
    border: _bordure(AppColors.iconSquare),
    enabledBorder: _bordure(AppColors.iconSquare),
    focusedBorder: _bordure(AppColors.primary),
    errorBorder: _bordure(AppColors.danger),
    focusedErrorBorder: _bordure(AppColors.danger),
  );
}

// Top bar of a form page: back arrow + centered purple title.
AppBar formAppBar(String titre) {
  return AppBar(
    title: Text(
      titre,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    ),
    centerTitle: true,
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    iconTheme: const IconThemeData(color: AppColors.primary),
  );
}
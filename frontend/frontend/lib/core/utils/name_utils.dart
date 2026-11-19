// Helpers to display a doctor's name the same way everywhere.

// Removes a leading "Dr" or "Dr." (any case) from a name.
String _sansTitre(String nom) {
  // Matches "dr" or "dr." followed by a space, at the very start.
  final titre = RegExp(r'^dr\.?\s+', caseSensitive: false);
  return nom.trim().replaceFirst(titre, '');
}

// "Martin" or "Dr. Martin" -> "Dr Martin"
String nomAvecTitre(String nom) => 'Dr ${_sansTitre(nom)}';

// "Martin" or "Dr Martin" -> "M" (letter shown in the avatar circle)
String initialeNom(String nom) {
  final sansTitre = _sansTitre(nom);
  return sansTitre.isEmpty ? '?' : sansTitre[0].toUpperCase();
}
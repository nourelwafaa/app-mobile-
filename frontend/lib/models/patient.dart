// A patient followed by the doctor.
class Patient {
  final int id;
  final String nom; // full name
  final DateTime derniereActivite; // date and time of the last activity

  const Patient({
    required this.id,
    required this.nom,
    required this.derniereActivite,
  });

  // First letter of the name, shown in the colored circle.
  String get initiale => nom[0].toUpperCase();
}
import '../constants/app_strings.dart';
import 'package:intl/intl.dart';

// Turns a date into text like "Aujourd'hui, 09:12", "Hier, 16:45" or "05/11, 10:30".
String formatActivite(DateTime date) {
  final now = DateTime.now();

  // Compare only the day (ignore the hour) to know how many days ago it was.
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(date.year, date.month, date.day);
  final daysAgo = today.difference(day).inDays;

  // Time as HH:mm (padLeft adds the leading zero: 9 -> 09).
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final time = '$hour:$minute';

  if (daysAgo == 0) return '${AppStrings.aujourdhui}, $time';
  if (daysAgo == 1) return '${AppStrings.hier}, $time';

  // Older than yesterday: show day/month.
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd/$mm, $time';
}

// "aujourd'hui, 09:12", "hier, 16:45" or "il y a 3 jours".
String formatSuivi(DateTime date) {
  final now = DateTime.now();

  // Compare only the day (ignore the hour).
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(date.year, date.month, date.day);
  final daysAgo = today.difference(day).inDays;

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  if (daysAgo == 0) return "aujourd'hui, $hour:$minute";
  if (daysAgo == 1) return 'hier, $hour:$minute';
  return 'il y a $daysAgo jours';

}

// "09:07"
String formatHeure(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// Number of calendar days between a date and today (0 = today).
int _joursDepuis(DateTime date) {
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(date.year, date.month, date.day);
  return today.difference(day).inDays;
}

// Time shown on the conversations list: "09:07", "Hier", "Lun." or "17/11".
String formatHeureListe(DateTime date) {
  final jours = _joursDepuis(date);
  if (jours == 0) return formatHeure(date);
  if (jours == 1) return AppStrings.hier;
  if (jours < 7) {
    const noms = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
    return noms[date.weekday - 1];
  }
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd/$mm';
}

// Day separator in a chat: "Aujourd'hui", "Hier" or "lundi 16 novembre".
String formatJourMessage(DateTime date) {
  final jours = _joursDepuis(date);
  if (jours == 0) return AppStrings.aujourdhui;
  if (jours == 1) return AppStrings.hier;
  return DateFormat('EEEE d MMMM', 'fr_FR').format(date);
}

// Group title on the notifications page: "Aujourd'hui", "Hier" or "Plus ancien".
String formatGroupeNotification(DateTime date) {
  final jours = _joursDepuis(date);
  if (jours == 0) return AppStrings.aujourdhui;
  if (jours == 1) return AppStrings.hier;
  return AppStrings.plusAncien;
}
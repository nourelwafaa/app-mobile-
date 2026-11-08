import '../constants/app_strings.dart';

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
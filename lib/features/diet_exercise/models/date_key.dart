/// Formats a [DateTime] as the `yyyy-MM-dd` day key used by every Phase 15
/// Firestore document (`water/{date}`, `workouts/{date}`, `daily_activity/{date}`).
///
/// Local time is used on purpose: a wellness day boundary should follow the
/// user's own clock, not UTC.
String dateKeyOf(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}

/// Parses a `yyyy-MM-dd` day key back into a local [DateTime].
///
/// Returns `null` for anything that is not a well-formed key so malformed
/// Firestore data can never crash the UI.
DateTime? dateFromKey(String? key) {
  if (key == null) return null;
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}
/// Formats a stored `HH:mm` punch time for attendance downloads.
///
/// `11:00` becomes `11:00 AM` and `21:00` becomes `9:00 PM`. Empty values stay
/// empty. Values that are already in AM/PM form are normalized, not doubled.
String formatAttendanceClock(String? time) {
  if (time == null) return '';
  final trimmed = time.trim();
  if (trimmed.isEmpty || trimmed == '-') return '';

  final twelveHour = RegExp(
    r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])$',
  ).firstMatch(trimmed);
  if (twelveHour != null) {
    final hour = int.tryParse(twelveHour.group(1)!);
    final minute = int.tryParse(twelveHour.group(2)!);
    if (hour == null || minute == null) return trimmed;
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return trimmed;
    final period = twelveHour.group(3)!.toUpperCase();
    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  }

  final twentyFourHour = RegExp(
    r'^(\d{1,2}):(\d{2})(?::\d{2})?$',
  ).firstMatch(trimmed);
  if (twentyFourHour == null) return trimmed;

  final hour24 = int.tryParse(twentyFourHour.group(1)!);
  final minute = int.tryParse(twentyFourHour.group(2)!);
  if (hour24 == null || minute == null) return trimmed;
  if (hour24 < 0 || hour24 > 23 || minute < 0 || minute > 59) return trimmed;

  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

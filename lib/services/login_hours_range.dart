class LoginHoursDateRange {
  const LoginHoursDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool get isSingleDay =>
      start.year == end.year && start.month == end.month && start.day == end.day;
}

enum LoginHoursPeriod { day, week, month, custom }

class LoginHoursRange {
  const LoginHoursRange();

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  LoginHoursDateRange resolve({
    required LoginHoursPeriod period,
    required DateTime anchor,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final day = dateOnly(anchor);
    switch (period) {
      case LoginHoursPeriod.day:
        return LoginHoursDateRange(start: day, end: day);
      case LoginHoursPeriod.week:
        final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
        final sunday = monday.add(const Duration(days: 6));
        return LoginHoursDateRange(start: monday, end: sunday);
      case LoginHoursPeriod.month:
        return LoginHoursDateRange(
          start: DateTime(day.year, day.month, 1),
          end: DateTime(day.year, day.month + 1, 0),
        );
      case LoginHoursPeriod.custom:
        final start = dateOnly(customStart ?? day);
        final end = dateOnly(customEnd ?? day);
        if (start.isAfter(end)) {
          return LoginHoursDateRange(start: end, end: start);
        }
        return LoginHoursDateRange(start: start, end: end);
    }
  }
}

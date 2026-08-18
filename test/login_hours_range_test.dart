import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/services/login_hours_range.dart';

void main() {
  const range = LoginHoursRange();

  test('day range is the anchor date', () {
    final result = range.resolve(
      period: LoginHoursPeriod.day,
      anchor: DateTime(2026, 8, 18),
    );
    expect(result.start, DateTime(2026, 8, 18));
    expect(result.end, DateTime(2026, 8, 18));
    expect(result.isSingleDay, isTrue);
  });

  test('week range is Monday through Sunday', () {
    final result = range.resolve(
      period: LoginHoursPeriod.week,
      anchor: DateTime(2026, 8, 18),
    );
    expect(result.start, DateTime(2026, 8, 17));
    expect(result.end, DateTime(2026, 8, 23));
  });

  test('month range is the calendar month', () {
    final result = range.resolve(
      period: LoginHoursPeriod.month,
      anchor: DateTime(2026, 8, 18),
    );
    expect(result.start, DateTime(2026, 8, 1));
    expect(result.end, DateTime(2026, 8, 31));
  });

  test('custom range uses the selected bounds', () {
    final result = range.resolve(
      period: LoginHoursPeriod.custom,
      anchor: DateTime(2026, 8, 18),
      customStart: DateTime(2026, 8, 10),
      customEnd: DateTime(2026, 8, 12),
    );
    expect(result.start, DateTime(2026, 8, 10));
    expect(result.end, DateTime(2026, 8, 12));
  });
}

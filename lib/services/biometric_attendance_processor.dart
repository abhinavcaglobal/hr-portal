import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/services/attendance_status_calculator.dart';
import 'package:hr_portal/services/biometric_sheet_parser.dart';

class BiometricAttendanceProcessor {
  const BiometricAttendanceProcessor({
    this.statusCalculator = const AttendanceStatusCalculator(),
  });

  final AttendanceStatusCalculator statusCalculator;

  BiometricProcessResult process({
    required String fileName,
    required BiometricSheetParseResult parsed,
    DateTime? today,
  }) {
    final punchesByEmployeeDate = <String, Map<String, List<BiometricPunch>>>{};

    for (final punch in parsed.punches) {
      punchesByEmployeeDate
          .putIfAbsent(punch.employeeId, () => {})
          .putIfAbsent(_dateKey(punch.date), () => [])
          .add(punch);
    }

    final periodStart = parsed.periodStart ?? _minDate(parsed.punches);
    final periodEnd = parsed.periodEnd ?? _maxDate(parsed.punches);
    final dates = _datesInRange(periodStart, periodEnd);
    final todayDate = _dateOnly(today ?? DateTime.now());

    final records = <BiometricDailyAttendance>[];
    for (final employee in BiometricEmployeeRoster.employees) {
      for (final date in dates) {
        // Upcoming days have no attendance yet — do not mark them Absent.
        if (date.isAfter(todayDate)) {
          continue;
        }

        if (_isWeekend(date)) {
          records.add(
            BiometricDailyAttendance(
              employeeId: employee.normalizedId,
              employeeName: employee.displayName,
              date: date,
              status: 'weekoff',
            ),
          );
          continue;
        }

        final punches =
            punchesByEmployeeDate[employee.normalizedId]?[_dateKey(date)] ??
            const <BiometricPunch>[];

        if (punches.isEmpty) {
          records.add(
            BiometricDailyAttendance(
              employeeId: employee.normalizedId,
              employeeName: employee.displayName,
              date: date,
              status: employee.isWfh
                  ? AttendanceStatus.wfh
                  : AttendanceStatus.absent,
            ),
          );
          continue;
        }

        final span = _daySpan(punches);
        final firstIn = span.firstIn;
        final lastOut = span.lastOut;
        final status = statusCalculator.calculate(
          firstIn: firstIn,
          lastOut: lastOut,
        );

        records.add(
          BiometricDailyAttendance(
            employeeId: employee.normalizedId,
            employeeName: employee.displayName,
            date: date,
            status: status,
            firstIn: firstIn,
            lastOut: lastOut,
          ),
        );
      }
    }

    return BiometricProcessResult(
      fileName: fileName,
      periodStart: periodStart,
      periodEnd: periodEnd,
      records: records,
    );
  }

  /// Earliest and latest punch that bound the working day.
  ///
  /// Normally these are the first IN and the last OUT. Biometric readers
  /// regularly mis-tag the closing punch of the day as an IN (and, more
  /// rarely, the opening punch as an OUT). When that happens the last OUT is
  /// only a mid-day break punch, which would collapse a full day into a few
  /// hours. In that case the day is bounded by the actual first/last punch
  /// recorded — no time is invented.
  ///
  /// A day with IN punches but no OUT at all keeps a null [lastOut] so it stays
  /// an incomplete record for HR to handle.
  ({String? firstIn, String? lastOut}) _daySpan(List<BiometricPunch> punches) {
    final sorted = [...punches]
      ..sort((a, b) => _compareTimes(a.time, b.time));

    final inTimes = sorted
        .where((punch) => punch.isIn)
        .map((punch) => punch.time)
        .toList();
    final outTimes = sorted
        .where((punch) => punch.isOut)
        .map((punch) => punch.time)
        .toList();

    var firstIn = inTimes.isEmpty ? null : inTimes.first;
    var lastOut = outTimes.isEmpty ? null : outTimes.last;

    if (firstIn == null || lastOut == null) {
      return (firstIn: firstIn, lastOut: lastOut);
    }

    final firstPunch = sorted.first.time;
    final lastPunch = sorted.last.time;

    if (_toMinutes(lastPunch) > _toMinutes(lastOut)) {
      lastOut = lastPunch;
    }
    if (_toMinutes(firstPunch) < _toMinutes(firstIn)) {
      firstIn = firstPunch;
    }

    return (firstIn: firstIn, lastOut: lastOut);
  }

  bool _isWeekend(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  List<DateTime> _datesInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(last)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  DateTime _minDate(List<BiometricPunch> punches) {
    return punches
        .map((punch) => punch.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime _maxDate(List<BiometricPunch> punches) {
    return punches
        .map((punch) => punch.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _compareTimes(String a, String b) {
    final minutesA = _toMinutes(a);
    final minutesB = _toMinutes(b);
    return minutesA.compareTo(minutesB);
  }

  int _toMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

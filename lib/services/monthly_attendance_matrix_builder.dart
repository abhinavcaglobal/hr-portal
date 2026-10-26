import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/models/attendance_month_note.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:intl/intl.dart';

class MonthlyAttendanceDayColumn {
  const MonthlyAttendanceDayColumn({
    required this.day,
    required this.date,
    required this.weekdayLabel,
  });

  final int day;
  final DateTime date;
  final String weekdayLabel;
}

class MonthlyAttendanceMatrixRow {
  const MonthlyAttendanceMatrixRow({
    required this.serial,
    required this.employeeName,
    this.employeeEmail,
    required this.statusByDay,
    this.remarks = '',
    this.reference = '',
  });

  final int serial;
  final String employeeName;
  final String? employeeEmail;
  final Map<int, String> statusByDay;
  final String remarks;
  final String reference;

  String statusForDay(int day) => statusByDay[day] ?? '';
}

class MonthlyAttendanceMatrix {
  const MonthlyAttendanceMatrix({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.dayColumns,
    required this.rows,
  });

  final int year;
  final int month;
  final String monthLabel;
  final List<MonthlyAttendanceDayColumn> dayColumns;
  final List<MonthlyAttendanceMatrixRow> rows;
}

/// Builds the wide employee×day attendance matrix used by admin UI and export.
class MonthlyAttendanceMatrixBuilder {
  const MonthlyAttendanceMatrixBuilder();

  static final DateFormat _monthFormat = DateFormat('MMMM');
  static final DateFormat _weekdayFormat = DateFormat('EEE');

  MonthlyAttendanceMatrix build({
    required int year,
    required int month,
    required List<String> employeeNames,
    required List<AttendanceRecord> records,
    required List<AttendanceMonthNote> notes,
    Map<String, String> emailByEmployeeName = const {},
    DateTime? today,
  }) {
    final dayColumns = _buildDayColumns(year, month);
    final statusIndex = <String, Map<int, String>>{};
    final todayDate = DateTime(
      (today ?? DateTime.now()).year,
      (today ?? DateTime.now()).month,
      (today ?? DateTime.now()).day,
    );

    for (final record in records) {
      if (record.date.year != year || record.date.month != month) continue;
      final status = record.status.trim().toUpperCase();
      if (status.isEmpty || status == '-') continue;

      for (final key in _indexKeysForStoredName(record.employeeName)) {
        final byDay = statusIndex.putIfAbsent(key, () => <int, String>{});
        byDay[record.date.day] = status;
      }
    }

    final notesIndex = <String, AttendanceMonthNote>{};
    for (final note in notes) {
      for (final key in _indexKeysForStoredName(note.employeeName)) {
        notesIndex.putIfAbsent(key, () => note);
      }
    }

    final rows = <MonthlyAttendanceMatrixRow>[];
    for (var i = 0; i < employeeNames.length; i++) {
      final name = employeeNames[i];
      final keys = lookupKeysForPortalName(name);
      final statusByDay = <int, String>{};
      AttendanceMonthNote? note;

      for (final key in keys) {
        final statuses = statusIndex[key];
        if (statuses != null) {
          statusByDay.addAll(statuses);
        }
        note ??= notesIndex[key];
      }

      // Past weekdays with no stored status default to Absent so the grid
      // never shows blank workdays. Weekends stay empty (shaded).
      for (final column in dayColumns) {
        if (statusByDay.containsKey(column.day)) continue;
        if (column.date.isAfter(todayDate)) continue;
        if (column.date.weekday == DateTime.saturday ||
            column.date.weekday == DateTime.sunday) {
          continue;
        }
        statusByDay[column.day] = 'A';
      }

      rows.add(
        MonthlyAttendanceMatrixRow(
          serial: i + 1,
          employeeName: name,
          employeeEmail: note?.employeeEmail ?? emailByEmployeeName[name],
          statusByDay: statusByDay,
          remarks: note?.remarks ?? '',
          reference: note?.reference ?? '',
        ),
      );
    }

    return MonthlyAttendanceMatrix(
      year: year,
      month: month,
      monthLabel: _monthFormat.format(DateTime(year, month)),
      dayColumns: dayColumns,
      rows: rows,
    );
  }

  List<MonthlyAttendanceDayColumn> _buildDayColumns(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return List.generate(daysInMonth, (index) {
      final day = index + 1;
      final date = DateTime(year, month, day);
      return MonthlyAttendanceDayColumn(
        day: day,
        date: date,
        weekdayLabel: _weekdayFormat.format(date),
      );
    });
  }

  /// Keys used when looking up a portal roster name (full name → short biometric).
  static List<String> lookupKeysForPortalName(String portalName) {
    final keys = <String>{normalizeEmployeeName(portalName)};
    final biometric = BiometricEmployeeRoster.findByEmployeeName(portalName);
    if (biometric != null) {
      keys.add(normalizeEmployeeName(biometric.name));
      keys.add(normalizeEmployeeName(biometric.displayName));
    }
    return keys.toList();
  }

  /// Keys used when indexing a stored attendance/note name.
  static Set<String> _indexKeysForStoredName(String storedName) {
    final keys = <String>{normalizeEmployeeName(storedName)};
    final biometric = BiometricEmployeeRoster.findByEmployeeName(storedName);
    if (biometric != null) {
      keys.add(normalizeEmployeeName(biometric.name));
      keys.add(normalizeEmployeeName(biometric.displayName));
    }
    return keys;
  }

  /// Lowercase, collapse spaces, strip trailing parenthetical suffixes like (WFH).
  static String normalizeEmployeeName(String name) {
    var value = name.trim().toLowerCase();
    value = value.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '');
    value = value.replaceAll(RegExp(r'\s+'), ' ');
    return value;
  }
}

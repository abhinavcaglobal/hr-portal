import 'package:hr_portal/core/constants/attendance_sheet_format.dart';
import 'package:hr_portal/core/errors/app_exception.dart';

class ParsedAttendanceCell {
  const ParsedAttendanceCell({
    required this.employeeName,
    required this.year,
    required this.month,
    required this.day,
    required this.status,
  });

  final String employeeName;
  final int year;
  final int month;
  final int day;
  final String status;

  String get dateKey =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

class AttendanceMatrixParseResult {
  const AttendanceMatrixParseResult({
    required this.records,
    required this.month,
    required this.year,
    required this.warnings,
  });

  final List<ParsedAttendanceCell> records;
  final int month;
  final int year;
  final List<String> warnings;
}

/// Parses HR wide-format attendance sheets (employees as rows, days as columns).
class AttendanceMatrixParser {
  const AttendanceMatrixParser({required this.year});

  final int year;

  static const Map<String, int> _monthNames = {
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  AttendanceMatrixParseResult parse(List<List<String>> rows) {
    if (rows.length < AttendanceSheetFormat.firstDataRowIndex + 1) {
      throw const DataException(
        'Attendance sheet is empty or missing data rows.',
      );
    }

    final headerRow = rows[AttendanceSheetFormat.headerRowIndex];
    final month = _parseMonth(headerRow);
    final dayColumns = _parseDayColumns(headerRow);

    if (dayColumns.isEmpty) {
      throw const DataException(
        'Could not find day columns. Row 1 should contain day numbers after the month name.',
      );
    }

    final records = <ParsedAttendanceCell>[];
    final warnings = <String>[];

    for (
      var rowIndex = AttendanceSheetFormat.firstDataRowIndex;
      rowIndex < rows.length;
      rowIndex++
    ) {
      final row = rows[rowIndex];
      if (row.length <= AttendanceSheetFormat.employeeNameColumnIndex) continue;

      final employeeName = row[AttendanceSheetFormat.employeeNameColumnIndex]
          .trim();
      if (employeeName.isEmpty ||
          employeeName.toLowerCase() == 'employee name') {
        continue;
      }

      for (final dayColumn in dayColumns) {
        if (dayColumn.columnIndex >= row.length) continue;

        final rawStatus = row[dayColumn.columnIndex].trim().toUpperCase();
        if (AttendanceSheetFormat.skipStatuses.contains(rawStatus) ||
            rawStatus.isEmpty) {
          continue;
        }

        if (!AttendanceSheetFormat.validStatuses.contains(rawStatus)) {
          warnings.add(
            '$employeeName on ${dayColumn.day}: unknown status "$rawStatus" (skipped).',
          );
          continue;
        }

        records.add(
          ParsedAttendanceCell(
            employeeName: employeeName,
            year: year,
            month: month,
            day: dayColumn.day,
            status: rawStatus,
          ),
        );
      }
    }

    if (records.isEmpty) {
      throw const DataException(
        'No attendance records found. Check employee names and status codes (P, L, HL, SL).',
      );
    }

    return AttendanceMatrixParseResult(
      records: records,
      month: month,
      year: year,
      warnings: warnings,
    );
  }

  int _parseMonth(List<String> headerRow) {
    if (headerRow.length <= AttendanceSheetFormat.employeeNameColumnIndex) {
      throw const DataException('Month name not found in cell B1.');
    }

    final monthText = headerRow[AttendanceSheetFormat.employeeNameColumnIndex]
        .trim();
    final month = _monthNames[monthText.toLowerCase()];
    if (month == null) {
      throw DataException(
        'Could not read month from "$monthText". Expected e.g. June, July.',
      );
    }
    return month;
  }

  List<_DayColumn> _parseDayColumns(List<String> headerRow) {
    final dayColumns = <_DayColumn>[];

    for (
      var col = AttendanceSheetFormat.firstDayColumnIndex;
      col < headerRow.length;
      col++
    ) {
      final cell = headerRow[col].trim();
      if (cell.isEmpty) break;

      final day = int.tryParse(cell);
      if (day == null || day < 1 || day > 31) break;

      dayColumns.add(_DayColumn(columnIndex: col, day: day));
    }

    return dayColumns;
  }
}

class _DayColumn {
  const _DayColumn({required this.columnIndex, required this.day});

  final int columnIndex;
  final int day;
}

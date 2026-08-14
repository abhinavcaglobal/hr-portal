import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/biometric_attendance.dart';

class BiometricSheetParser {
  const BiometricSheetParser();

  static const _headerName = 'name';
  static const _headerId = 'id';
  static const _headerDate = 'date';
  static const _headerTime = 'time';
  static const _headerCheckPoint = 'attendance check point';

  BiometricSheetParseResult parse(List<List<String>> rows) {
    if (rows.isEmpty) {
      throw const DataException('Biometric sheet is empty.');
    }

    final period = _parseTimePeriod(rows);
    final headerIndex = _findHeaderRowIndex(rows);
    if (headerIndex == null) {
      throw const DataException(
        'Could not find biometric header row (Name, ID, Date, Time, ...).',
      );
    }

    final header = rows[headerIndex].map((cell) => cell.toLowerCase()).toList();
    final nameIndex = header.indexOf(_headerName);
    final idIndex = header.indexOf(_headerId);
    final dateIndex = header.indexOf(_headerDate);
    final timeIndex = header.indexOf(_headerTime);
    final checkPointIndex = header.indexOf(_headerCheckPoint);

    if ([
      nameIndex,
      idIndex,
      dateIndex,
      timeIndex,
      checkPointIndex,
    ].any((index) => index < 0)) {
      throw const DataException(
        'Invalid biometric headers. Expected: Name, ID, Date, Time, Attendance Check Point.',
      );
    }

    final punches = <BiometricPunch>[];
    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= checkPointIndex) continue;

      final name = row[nameIndex].trim();
      final id = row[idIndex].trim();
      final dateText = row[dateIndex].trim();
      final time = row[timeIndex].trim();
      final checkPoint = row[checkPointIndex].trim();

      if (name.isEmpty || id.isEmpty || dateText.isEmpty || time.isEmpty) {
        continue;
      }

      final date = DateTime.tryParse(dateText);
      if (date == null) continue;

      final upperCheckPoint = checkPoint.toUpperCase();
      punches.add(
        BiometricPunch(
          employeeId: id.padLeft(3, '0'),
          employeeName: name,
          date: DateTime(date.year, date.month, date.day),
          time: time,
          isIn: upperCheckPoint.contains('IN-'),
          isOut: upperCheckPoint.contains('OUT-'),
        ),
      );
    }

    if (punches.isEmpty) {
      throw const DataException(
        'No biometric punch records found in the sheet.',
      );
    }

    return BiometricSheetParseResult(
      periodStart: period?.start,
      periodEnd: period?.end,
      punches: punches,
    );
  }

  int? _findHeaderRowIndex(List<List<String>> rows) {
    for (var i = 0; i < rows.length; i++) {
      final lower = rows[i].map((cell) => cell.toLowerCase()).toList();
      if (lower.contains(_headerName) &&
          lower.contains(_headerId) &&
          lower.contains(_headerDate)) {
        return i;
      }
    }
    return null;
  }

  _DateRange? _parseTimePeriod(List<List<String>> rows) {
    final pattern = RegExp(r'(\d{4}-\d{2}-\d{2})\s*-\s*(\d{4}-\d{2}-\d{2})');

    for (final row in rows.take(12)) {
      final text = row.join(' ');
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final start = DateTime.tryParse(match.group(1)!);
      final end = DateTime.tryParse(match.group(2)!);
      if (start == null || end == null) continue;

      return _DateRange(
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(end.year, end.month, end.day),
      );
    }

    return null;
  }
}

class BiometricSheetParseResult {
  const BiometricSheetParseResult({
    required this.periodStart,
    required this.periodEnd,
    required this.punches,
  });

  final DateTime? periodStart;
  final DateTime? periodEnd;
  final List<BiometricPunch> punches;
}

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

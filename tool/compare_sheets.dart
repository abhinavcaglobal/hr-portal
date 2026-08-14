import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:hr_portal/services/attendance_matrix_parser.dart';

void main() {
  final roster = _loadRoster('Employees Email id.xlsx');
  final attendanceNames = _loadAttendanceNames('Attendance - June(Attendance ).csv');

  stdout.writeln('=== ROSTER (${roster.length} employees) ===');
  for (final e in roster) {
    stdout.writeln('  ${e.name} | ${e.email}');
  }

  stdout.writeln('\n=== ATTENDANCE (${attendanceNames.length} employees) ===');
  for (final n in attendanceNames) {
    stdout.writeln('  "$n"');
  }

  final rosterByNormalizedName = {
    for (final e in roster) _norm(e.name): e,
  };

  stdout.writeln('\n=== IN ATTENDANCE BUT NOT IN ROSTER (by exact normalized name) ===');
  for (final name in attendanceNames) {
    final key = _norm(name);
    if (!rosterByNormalizedName.containsKey(key)) {
      stdout.writeln('  ATT: "$name"');
      final fuzzy = roster.where(
        (e) => _norm(e.name).contains(key) || key.contains(_norm(e.name)),
      );
      for (final f in fuzzy) {
        stdout.writeln('    possible roster match: "${f.name}" <${f.email}>');
      }
    }
  }

  stdout.writeln('\n=== IN ROSTER BUT NOT IN ATTENDANCE ===');
  final attNorm = attendanceNames.map(_norm).toSet();
  for (final e in roster) {
    if (!attNorm.contains(_norm(e.name))) {
      stdout.writeln('  ROSTER: "${e.name}" <${e.email}>');
    }
  }

  stdout.writeln('\n=== ABHINAV BATHLA CHECK ===');
  final abhinavRoster = roster.where(
    (e) => e.email.toLowerCase() == 'abhinav.bathla@caglobal.com',
  );
  final abhinavAtt = attendanceNames.where(
    (n) => _norm(n) == _norm('Abhinav Bathla'),
  );
  stdout.writeln('Roster entries: $abhinavRoster');
  stdout.writeln('Attendance names: $abhinavAtt');

  final parser = AttendanceMatrixParser(year: 2026);
  final csv = const CsvToListConverter().convert(
    File('Attendance - June(Attendance ).csv').readAsStringSync(),
    shouldParseNumbers: false,
  );
  final rows = csv.map((r) => r.map((c) => c?.toString() ?? '').toList()).toList();
  final parsed = parser.parse(rows);
  final abhinavRecords =
      parsed.records.where((r) => _norm(r.employeeName) == _norm('Abhinav Bathla'));
  stdout.writeln('Parsed Abhinav attendance cells: ${abhinavRecords.length}');
  if (abhinavRecords.isNotEmpty) {
    stdout.writeln('Sample: ${abhinavRecords.first.employeeName} ${abhinavRecords.first.dateKey} ${abhinavRecords.first.status}');
  }
}

String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

List<_RosterEntry> _loadRoster(String path) {
  final bytes = File(path).readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  final sheet = excel.tables.values.first;
  final entries = <_RosterEntry>[];
  for (var r = 1; r < sheet.maxRows; r++) {
    final row = sheet.row(r);
    final name = row.isNotEmpty ? (row[0]?.value?.toString() ?? '').trim() : '';
    final email = row.length > 1 ? (row[1]?.value?.toString() ?? '').trim() : '';
    if (name.isEmpty || email.isEmpty) continue;
    entries.add(_RosterEntry(name, email.toLowerCase()));
  }
  return entries;
}

List<String> _loadAttendanceNames(String path) {
  final csv = const CsvToListConverter().convert(
    File(path).readAsStringSync(),
    shouldParseNumbers: false,
  );
  final rows = csv.map((r) => r.map((c) => c?.toString() ?? '').toList()).toList();
  final names = <String>[];
  for (var i = 2; i < rows.length; i++) {
    if (rows[i].length < 2) continue;
    final name = rows[i][1].trim();
    if (name.isEmpty || name.toLowerCase() == 'employee name') continue;
    if (name.toLowerCase().startsWith('present')) break;
    names.add(name);
  }
  return names;
}

class _RosterEntry {
  _RosterEntry(this.name, this.email);
  final String name;
  final String email;

  @override
  String toString() => '$name <$email>';
}

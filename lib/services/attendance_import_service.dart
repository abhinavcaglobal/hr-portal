import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/repositories/attendance_repository.dart';
import 'package:hr_portal/repositories/employee_repository.dart';
import 'package:hr_portal/services/attendance_matrix_parser.dart';
import 'package:hr_portal/services/spreadsheet_reader_service.dart';

class AttendanceImportResult {
  const AttendanceImportResult({
    required this.importedCount,
    required this.warnings,
    required this.month,
    required this.year,
  });

  final int importedCount;
  final List<String> warnings;
  final int month;
  final int year;

  String get summary {
    final monthName = DateFormat.MMMM().format(DateTime(year, month));
    return 'Imported $importedCount attendance record(s) for $monthName $year.';
  }
}

class AttendanceImportService {
  AttendanceImportService({
    required EmployeeRepository employeeRepository,
    required AttendanceRepository attendanceRepository,
  }) : _employeeRepository = employeeRepository,
       _attendanceRepository = attendanceRepository;

  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;

  Future<AttendanceImportResult> importFromFile({
    required Uint8List bytes,
    required String fileName,
    required int year,
  }) async {
    final rows = SpreadsheetReader.readRows(bytes: bytes, fileName: fileName);
    final parsed = AttendanceMatrixParser(year: year).parse(rows);

    final knownNames = await _loadKnownEmployeeNames();
    final emailByName = await _loadEmployeeEmailsByName();
    final records = <AttendanceRecord>[];

    for (final cell in parsed.records) {
      if (!knownNames.contains(cell.employeeName)) {
        await _employeeRepository.upsertEmployeeByName(
          name: cell.employeeName,
          openingBalance: 0,
        );
        knownNames.add(cell.employeeName);
      }

      final email = _lookupEmail(cell.employeeName, emailByName);

      records.add(
        AttendanceRecord(
          employeeName: cell.employeeName,
          employeeEmail: email,
          date: DateTime(cell.year, cell.month, cell.day),
          status: cell.status,
        ),
      );
    }

    await _attendanceRepository.importAttendanceRecords(records);

    return AttendanceImportResult(
      importedCount: records.length,
      warnings: parsed.warnings,
      month: parsed.month,
      year: parsed.year,
    );
  }

  Future<Set<String>> _loadKnownEmployeeNames() async {
    final employees = await _employeeRepository.getAllEmployees();
    return employees.map((e) => e.name).toSet();
  }

  Future<Map<String, String>> _loadEmployeeEmailsByName() async {
    final employees = await _employeeRepository.getAllEmployees();
    final map = <String, String>{};
    for (final employee in employees) {
      if (employee.email.isEmpty) continue;
      final email = employee.email.toLowerCase();
      map[employee.name] = email;
      map[_normalizeName(employee.name)] = email;
    }
    return map;
  }

  String? _lookupEmail(String attendanceName, Map<String, String> emailByName) {
    final trimmed = attendanceName.trim();
    return emailByName[trimmed] ?? emailByName[_normalizeName(trimmed)];
  }

  String _normalizeName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

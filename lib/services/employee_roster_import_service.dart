import 'dart:typed_data';

import 'package:hr_portal/repositories/employee_repository.dart';
import 'package:hr_portal/services/employee_roster_parser.dart';
import 'package:hr_portal/services/spreadsheet_reader_service.dart';

class EmployeeRosterImportResult {
  const EmployeeRosterImportResult({required this.importedCount});

  final int importedCount;

  String get summary => 'Imported roster for $importedCount employee(s).';
}

class EmployeeRosterImportService {
  EmployeeRosterImportService(this._employeeRepository);

  final EmployeeRepository _employeeRepository;

  Future<EmployeeRosterImportResult> importFromFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final rows = SpreadsheetReader.readRows(bytes: bytes, fileName: fileName);
    final employees = const EmployeeRosterParser().parse(rows);

    await _employeeRepository.importOpeningBalances(employees);

    return EmployeeRosterImportResult(importedCount: employees.length);
  }
}

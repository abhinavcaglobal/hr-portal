import 'dart:typed_data';

import 'package:hr_portal/repositories/employee_repository.dart';
import 'package:hr_portal/services/opening_balance_parser.dart';
import 'package:hr_portal/services/spreadsheet_reader_service.dart';

class OpeningBalanceImportResult {
  const OpeningBalanceImportResult({required this.importedCount});

  final int importedCount;

  String get summary =>
      'Imported opening balance for $importedCount employee(s).';
}

class OpeningBalanceImportService {
  OpeningBalanceImportService(this._employeeRepository);

  final EmployeeRepository _employeeRepository;

  Future<OpeningBalanceImportResult> importFromFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final rows = SpreadsheetReader.readRows(bytes: bytes, fileName: fileName);
    final employees = const OpeningBalanceParser().parse(rows);

    await _employeeRepository.importOpeningBalances(employees);

    return OpeningBalanceImportResult(importedCount: employees.length);
  }
}

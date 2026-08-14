import 'dart:io';

import 'package:hr_portal/services/opening_balance_parser.dart';
import 'package:hr_portal/services/spreadsheet_reader_service.dart';

void main() {
  final bytes = File('Atten.xlsx').readAsBytesSync();
  final rows = SpreadsheetReader.readRows(
    bytes: bytes,
    fileName: 'Atten.xlsx',
  );

  final employees = const OpeningBalanceParser().parse(rows);
  print('Employees parsed: ${employees.length}');
  print('');
  print('First 5:');
  for (final e in employees.take(5)) {
    print('  ${e.name} -> ${e.openingBalance}');
  }
  print('');
  print('Last 3:');
  for (final e in employees.skip(employees.length - 3)) {
    print('  ${e.name} -> ${e.openingBalance}');
  }
}

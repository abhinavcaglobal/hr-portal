import 'dart:io';

import 'package:excel/excel.dart';

void main() {
  final bytes = File('Employees Email id.xlsx').readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  for (final table in excel.tables.keys) {
    stdout.writeln('Sheet: $table');
    final sheet = excel.tables[table]!;
    for (var r = 0; r < sheet.maxRows; r++) {
      final row = sheet.row(r);
      final cells = row.map((c) => c?.value?.toString() ?? '').toList();
      if (cells.any((c) => c.trim().isNotEmpty)) {
        stdout.writeln('${r + 1}: $cells');
      }
    }
  }
}

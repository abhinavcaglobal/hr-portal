import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:hr_portal/core/constants/upload_file_types.dart';
import 'package:hr_portal/core/errors/app_exception.dart';

class SpreadsheetReader {
  SpreadsheetReader._();

  static List<List<String>> readRows({
    required Uint8List bytes,
    required String fileName,
  }) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    return switch (extension) {
      'csv' => _readCsv(bytes),
      'xlsx' => _readXlsx(bytes),
      'xls' => throw const DataException(
        'Legacy .xls files are not supported. Save as .csv or .xlsx.',
      ),
      _ => throw DataException(
        'Unsupported file type. Use: '
        '${UploadFileTypes.allowedExtensions.join(', ')}.',
      ),
    };
  }

  static List<List<String>> _readCsv(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final rows = const CsvToListConverter().convert(content);

    return rows
        .map((row) => row.map((cell) => cell?.toString().trim() ?? '').toList())
        .toList();
  }

  static List<List<String>> _readXlsx(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw const DataException('The Excel file has no sheets.');
    }

    final sheet = workbook.tables.values.first;
    final rows = <List<String>>[];

    for (var rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
      final row = <String>[];
      var hasValue = false;

      for (var colIndex = 0; colIndex < sheet.maxColumns; colIndex++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex),
        );
        final value = cell.value;
        final text = value == null ? '' : value.toString().trim();
        if (text.isNotEmpty) hasValue = true;
        row.add(text);
      }

      if (hasValue) {
        rows.add(row);
      }
    }

    return rows;
  }
}

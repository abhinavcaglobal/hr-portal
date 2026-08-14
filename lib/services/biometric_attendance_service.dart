import 'dart:typed_data';

import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/services/biometric_attendance_excel_exporter.dart';
import 'package:hr_portal/services/biometric_attendance_processor.dart';
import 'package:hr_portal/services/biometric_sheet_parser.dart';
import 'package:hr_portal/services/spreadsheet_reader_service.dart';

class BiometricAttendanceService {
  const BiometricAttendanceService({
    BiometricSheetParser? parser,
    BiometricAttendanceProcessor? processor,
    BiometricAttendanceExcelExporter? excelExporter,
  }) : _parser = parser ?? const BiometricSheetParser(),
       _processor = processor ?? const BiometricAttendanceProcessor(),
       _excelExporter =
           excelExporter ?? const BiometricAttendanceExcelExporter();

  final BiometricSheetParser _parser;
  final BiometricAttendanceProcessor _processor;
  final BiometricAttendanceExcelExporter _excelExporter;

  BiometricProcessResult processFile({
    required Uint8List bytes,
    required String fileName,
  }) {
    final rows = SpreadsheetReader.readRows(bytes: bytes, fileName: fileName);
    final parsed = _parser.parse(rows);
    return _processor.process(fileName: fileName, parsed: parsed);
  }

  Uint8List toExcelBytes(BiometricProcessResult result) {
    return _excelExporter.export(result);
  }

  String excelFileName(BiometricProcessResult result) {
    return _excelExporter.suggestedFileName(result);
  }

  String toCsv(BiometricProcessResult result) {
    final buffer = StringBuffer('Name,ID,Date,Status,First IN,Last OUT\n');
    for (final record in result.records) {
      buffer.writeln(
        '${_escape(record.employeeName)},'
        '${record.employeeId},'
        '${_formatDate(record.date)},'
        '${record.status},'
        '${record.firstIn ?? ''},'
        '${record.lastOut ?? ''}',
      );
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _escape(String value) {
    if (value.contains(',') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

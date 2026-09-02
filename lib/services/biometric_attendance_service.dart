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

  String csvFileName(BiometricProcessResult result) {
    final start = _formatDate(result.periodStart);
    final end = _formatDate(result.periodEnd);
    return 'attendance_${start}_to_$end.csv';
  }

  String toCsv(BiometricProcessResult result) {
    final recordsByDate = <String, List<BiometricDailyAttendance>>{};
    for (final record in result.records) {
      final dateKey = _formatDate(record.date);
      recordsByDate.putIfAbsent(dateKey, () => []).add(record);
    }

    final sortedDates = recordsByDate.keys.toList()..sort();
    final buffer = StringBuffer();

    for (final dateKey in sortedDates) {
      final dayRecords = recordsByDate[dateKey]!
        ..sort((a, b) => a.employeeId.compareTo(b.employeeId));
      final date = dayRecords.first.date;

      buffer.writeln(_formatDateHeader(date));
      buffer.writeln('S.No,Employee Name,IN,OUT,Status,Remarks');

      for (var index = 0; index < dayRecords.length; index++) {
        final record = dayRecords[index];
        buffer.writeln(
          '${index + 1},'
          '${_escape(record.employeeName)},'
          '${record.firstIn ?? ''},'
          '${record.lastOut ?? ''},'
          '${record.status},',
        );
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDateHeader(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = date.day;
    return 'Date : $day${_ordinalSuffix(day)} ${months[date.month - 1]} ${date.year}';
  }

  String _ordinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

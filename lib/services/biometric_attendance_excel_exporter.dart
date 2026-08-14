import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/models/biometric_attendance.dart';

class BiometricAttendanceExcelExporter {
  const BiometricAttendanceExcelExporter();

  Uint8List export(BiometricProcessResult result) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, 'Attendance');
    }

    final sheet = excel['Attendance'];
    final recordsByDate = <String, List<BiometricDailyAttendance>>{};

    for (final record in result.records) {
      final dateKey = _formatDate(record.date);
      recordsByDate.putIfAbsent(dateKey, () => []).add(record);
    }

    final sortedDates = recordsByDate.keys.toList()..sort();
    var rowIndex = 0;

    for (final date in sortedDates) {
      final dayRecords = recordsByDate[date]!
        ..sort((a, b) => a.employeeId.compareTo(b.employeeId));

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(
        date,
      );
      rowIndex++;

      const headers = ['S.No.', 'Name', 'ID', 'IN Time', 'Out Time'];
      for (var column = 0; column < headers.length; column++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: column,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(
          headers[column],
        );
      }
      rowIndex++;

      for (var index = 0; index < dayRecords.length; index++) {
        final record = dayRecords[index];
        final times = _displayTimes(record);

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = IntCellValue(
          index + 1,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          record.employeeName,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          record.employeeId,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          times.inTime,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          times.outTime,
        );
        rowIndex++;
      }

      rowIndex++;
    }

    final bytes = excel.encode();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Failed to generate attendance Excel file.');
    }

    return Uint8List.fromList(bytes);
  }

  ({String inTime, String outTime}) _displayTimes(
    BiometricDailyAttendance record,
  ) {
    if (record.isWeekOff) {
      return (inTime: 'weekoff', outTime: '');
    }
    if (record.isWfh) {
      return (inTime: AttendanceStatus.wfh, outTime: '');
    }
    if (record.isAbsent) {
      return (inTime: AttendanceStatus.absent, outTime: '');
    }
    if (record.isLeave) {
      return (inTime: AttendanceStatus.leave, outTime: '');
    }
    return (inTime: record.firstIn ?? '', outTime: record.lastOut ?? '');
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String suggestedFileName(BiometricProcessResult result) {
    final start = _formatDate(result.periodStart);
    final end = _formatDate(result.periodEnd);
    return 'attendance_${start}_to_$end.xlsx';
  }
}

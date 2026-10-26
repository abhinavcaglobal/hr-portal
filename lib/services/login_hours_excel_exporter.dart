import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/core/utils/attendance_clock_format.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/services/login_hours_display_service.dart';
import 'package:intl/intl.dart';

/// Exports login-hours rows in the HR attendance sheet layout:
/// Date header + S.No | Employee Name | IN | OUT | Status | Remarks.
class LoginHoursExcelExporter {
  const LoginHoursExcelExporter({
    this.displayService = const LoginHoursDisplayService(),
  });

  final LoginHoursDisplayService displayService;

  static final ExcelColor _headerFill = ExcelColor.fromHexString('F8CBAD');
  static final Border _thinBorder = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: ExcelColor.black,
  );

  Uint8List export(List<LoginHoursRecord> records) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, 'Login Hours');
    }

    final sheet = excel['Login Hours'];
    sheet.setColumnWidth(0, 10);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 24);

    final recordsByDate = <String, List<LoginHoursRecord>>{};
    for (final record in records) {
      final dateKey = _sortKey(record.date);
      recordsByDate.putIfAbsent(dateKey, () => []).add(record);
    }

    final sortedDates = recordsByDate.keys.toList()..sort();
    var rowIndex = 0;

    for (final dateKey in sortedDates) {
      final dayRecords = recordsByDate[dateKey]!
        ..sort(
          (a, b) => BiometricEmployeeRoster.compareReportOrder(
            aName: a.employeeName,
            aId: a.employeeId,
            bName: b.employeeName,
            bId: b.employeeId,
          ),
        );
      final date = dayRecords.first.date;

      _writeDateHeader(sheet, rowIndex: rowIndex, date: date);
      rowIndex++;
      _writeColumnHeaders(sheet, rowIndex: rowIndex);
      rowIndex++;

      for (var index = 0; index < dayRecords.length; index++) {
        final record = dayRecords[index];
        final display = displayService.format(
          record: record,
          selectedDate: record.date,
        );
        _writeDataRow(
          sheet,
          rowIndex: rowIndex,
          serial: index + 1,
          employeeName: record.employeeName,
          inTime: formatAttendanceClock(display.inTime),
          outTime: formatAttendanceClock(display.outTime),
          status: display.status,
          remarks: display.remarks,
        );
        rowIndex++;
      }

      rowIndex++;
    }

    final bytes = excel.encode();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Failed to generate login hours Excel file.');
    }
    return Uint8List.fromList(bytes);
  }

  String suggestedFileName(List<LoginHoursRecord> records) {
    if (records.isEmpty) {
      final today = _sortKey(DateTime.now());
      return 'login_hours_$today.xlsx';
    }
    final dates = records.map((record) => record.date).toList()..sort();
    final start = _sortKey(dates.first);
    final end = _sortKey(dates.last);
    if (start == end) {
      return 'login_hours_$start.xlsx';
    }
    return 'login_hours_${start}_to_$end.xlsx';
  }

  void _writeDateHeader(
    Sheet sheet, {
    required int rowIndex,
    required DateTime date,
  }) {
    final style = CellStyle(
      backgroundColorHex: _headerFill,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: _thinBorder,
      rightBorder: _thinBorder,
      topBorder: _thinBorder,
      bottomBorder: _thinBorder,
    );

    for (var column = 0; column < 6; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowIndex),
      );
      cell.cellStyle = style;
      if (column == 0) {
        cell.value = TextCellValue(_formatDateHeader(date));
      }
    }

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
      customValue: TextCellValue(_formatDateHeader(date)),
    );
  }

  void _writeColumnHeaders(Sheet sheet, {required int rowIndex}) {
    const headers = [
      'S.No',
      'Employee Name',
      'IN',
      'OUT',
      'Status',
      'Remarks',
    ];
    final style = CellStyle(
      backgroundColorHex: _headerFill,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: _thinBorder,
      rightBorder: _thinBorder,
      topBorder: _thinBorder,
      bottomBorder: _thinBorder,
    );

    for (var column = 0; column < headers.length; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowIndex),
      );
      cell.value = TextCellValue(headers[column]);
      cell.cellStyle = style;
    }
  }

  void _writeDataRow(
    Sheet sheet, {
    required int rowIndex,
    required int serial,
    required String employeeName,
    required String inTime,
    required String outTime,
    required String status,
    required String remarks,
  }) {
    final style = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: _thinBorder,
      rightBorder: _thinBorder,
      topBorder: _thinBorder,
      bottomBorder: _thinBorder,
    );
    final values = <CellValue>[
      IntCellValue(serial),
      TextCellValue(employeeName),
      TextCellValue(inTime),
      TextCellValue(outTime),
      TextCellValue(status),
      TextCellValue(remarks),
    ];

    for (var column = 0; column < values.length; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowIndex),
      );
      cell.value = values[column];
      cell.cellStyle = style;
    }
  }

  String _formatDateHeader(DateTime date) {
    final day = date.day;
    final monthYear = DateFormat('MMMM yyyy').format(date);
    return 'Date : $day${_ordinalSuffix(day)} $monthYear';
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

  String _sortKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

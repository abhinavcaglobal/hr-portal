import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/services/monthly_attendance_matrix_builder.dart';

/// Exports the monthly attendance matrix in HR wide-sheet layout.
class MonthlyAttendanceExcelExporter {
  const MonthlyAttendanceExcelExporter();

  static final ExcelColor _headerFill = ExcelColor.fromHexString('F8CBAD');
  static final Border _thinBorder = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: ExcelColor.black,
  );

  Uint8List export(MonthlyAttendanceMatrix matrix) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, 'Attendance');
    }

    final sheet = excel['Attendance'];
    final dayCount = matrix.dayColumns.length;
    final remarksCol = 2 + dayCount;
    final referenceCol = remarksCol + 1;
    final totalCols = referenceCol + 1;

    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 28);
    for (var i = 0; i < dayCount; i++) {
      sheet.setColumnWidth(2 + i, 5);
    }
    sheet.setColumnWidth(remarksCol, 36);
    sheet.setColumnWidth(referenceCol, 40);

    final headerStyle = CellStyle(
      backgroundColorHex: _headerFill,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: _thinBorder,
      rightBorder: _thinBorder,
      topBorder: _thinBorder,
      bottomBorder: _thinBorder,
    );
    final cellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: _thinBorder,
      rightBorder: _thinBorder,
      topBorder: _thinBorder,
      bottomBorder: _thinBorder,
    );
    final leftStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: _thinBorder,
      rightBorder: _thinBorder,
      topBorder: _thinBorder,
      bottomBorder: _thinBorder,
    );

    // Row 1: S.no | Month | day numbers | Remarks | Reference
    _setCell(sheet, 0, 0, TextCellValue('S.no'), headerStyle);
    _setCell(sheet, 1, 0, TextCellValue(matrix.monthLabel), headerStyle);
    for (var i = 0; i < dayCount; i++) {
      _setCell(
        sheet,
        2 + i,
        0,
        IntCellValue(matrix.dayColumns[i].day),
        headerStyle,
      );
    }
    _setCell(sheet, remarksCol, 0, TextCellValue('Remarks'), headerStyle);
    _setCell(sheet, referenceCol, 0, TextCellValue('Reference'), headerStyle);

    // Row 2: blank | EMPLOYEE NAME | weekdays
    _setCell(sheet, 0, 1, TextCellValue(''), headerStyle);
    _setCell(sheet, 1, 1, TextCellValue('EMPLOYEE NAME'), headerStyle);
    for (var i = 0; i < dayCount; i++) {
      _setCell(
        sheet,
        2 + i,
        1,
        TextCellValue(matrix.dayColumns[i].weekdayLabel),
        headerStyle,
      );
    }
    _setCell(sheet, remarksCol, 1, TextCellValue(''), headerStyle);
    _setCell(sheet, referenceCol, 1, TextCellValue(''), headerStyle);

    for (final row in matrix.rows) {
      final rowIndex = row.serial + 1; // serial 1 → sheet row 2 (0-based +2)
      _setCell(sheet, 0, rowIndex, IntCellValue(row.serial), cellStyle);
      _setCell(sheet, 1, rowIndex, TextCellValue(row.employeeName), leftStyle);
      for (var i = 0; i < dayCount; i++) {
        final day = matrix.dayColumns[i].day;
        final status = row.statusForDay(day);
        _setCell(sheet, 2 + i, rowIndex, TextCellValue(status), cellStyle);
      }
      _setCell(sheet, remarksCol, rowIndex, TextCellValue(row.remarks), leftStyle);
      _setCell(
        sheet,
        referenceCol,
        rowIndex,
        TextCellValue(row.reference),
        leftStyle,
      );
    }

    var legendRow = matrix.rows.length + 3;
    final legendEntries = <(String, String)>[
      ('Present', AttendanceStatus.present),
      ('Leave', AttendanceStatus.leave),
      ('Half Leave', AttendanceStatus.halfLeave),
      ('Short Leave', AttendanceStatus.shortLeave),
      ('Late Punch', AttendanceStatus.latePunch),
      ('Unpaid Leave', AttendanceStatus.unpaidLeave),
      ('Absent', AttendanceStatus.absent),
      ('Work From Home', AttendanceStatus.wfh),
      ('N/A', '-'),
    ];
    for (final entry in legendEntries) {
      _setCell(sheet, 1, legendRow, TextCellValue(entry.$1), leftStyle);
      _setCell(sheet, 2, legendRow, TextCellValue(entry.$2), cellStyle);
      legendRow++;
    }

    // Touch last column so empty styled cells exist for headers.
    for (var col = 0; col < totalCols; col++) {
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
    }

    final bytes = excel.encode();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Failed to generate monthly attendance Excel file.');
    }
    return Uint8List.fromList(bytes);
  }

  String suggestedFileName(MonthlyAttendanceMatrix matrix) {
    final month = matrix.month.toString().padLeft(2, '0');
    return 'Attendance_${matrix.monthLabel}_$month-${matrix.year}.xlsx';
  }

  void _setCell(
    Sheet sheet,
    int column,
    int row,
    CellValue value,
    CellStyle style,
  ) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
    );
    cell.value = value;
    cell.cellStyle = style;
  }
}

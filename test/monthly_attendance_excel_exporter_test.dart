import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/services/monthly_attendance_excel_exporter.dart';
import 'package:hr_portal/services/monthly_attendance_matrix_builder.dart';

void main() {
  const exporter = MonthlyAttendanceExcelExporter();

  test('exports wide-matrix headers, statuses, and notes', () {
    final matrix = MonthlyAttendanceMatrix(
      year: 2026,
      month: 6,
      monthLabel: 'June',
      dayColumns: [
        MonthlyAttendanceDayColumn(
          day: 1,
          date: DateTime(2026, 6, 1),
          weekdayLabel: 'Mon',
        ),
        MonthlyAttendanceDayColumn(
          day: 2,
          date: DateTime(2026, 6, 2),
          weekdayLabel: 'Tue',
        ),
      ],
      rows: const [
        MonthlyAttendanceMatrixRow(
          serial: 1,
          employeeName: 'Mayur Kumar',
          statusByDay: {1: 'P', 2: 'L'},
          remarks: 'OK',
          reference: 'Joined early',
        ),
      ],
    );

    final bytes = exporter.export(matrix);
    expect(bytes, isNotEmpty);
    expect(exporter.suggestedFileName(matrix), 'Attendance_June_06-2026.xlsx');

    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook['Attendance'];

    expect(sheet.cell(CellIndex.indexByString('A1')).value?.toString(), 'S.no');
    expect(sheet.cell(CellIndex.indexByString('B1')).value?.toString(), 'June');
    expect(sheet.cell(CellIndex.indexByString('C1')).value?.toString(), '1');
    expect(sheet.cell(CellIndex.indexByString('D1')).value?.toString(), '2');
    expect(
      sheet.cell(CellIndex.indexByString('E1')).value?.toString(),
      'Remarks',
    );
    expect(
      sheet.cell(CellIndex.indexByString('F1')).value?.toString(),
      'Reference',
    );

    expect(sheet.cell(CellIndex.indexByString('B2')).value?.toString(), 'EMPLOYEE NAME');
    expect(sheet.cell(CellIndex.indexByString('C2')).value?.toString(), 'Mon');
    expect(sheet.cell(CellIndex.indexByString('D2')).value?.toString(), 'Tue');

    expect(sheet.cell(CellIndex.indexByString('A3')).value?.toString(), '1');
    expect(
      sheet.cell(CellIndex.indexByString('B3')).value?.toString(),
      'Mayur Kumar',
    );
    expect(sheet.cell(CellIndex.indexByString('C3')).value?.toString(), 'P');
    expect(sheet.cell(CellIndex.indexByString('D3')).value?.toString(), 'L');
    expect(sheet.cell(CellIndex.indexByString('E3')).value?.toString(), 'OK');
    expect(
      sheet.cell(CellIndex.indexByString('F3')).value?.toString(),
      'Joined early',
    );
  });
}

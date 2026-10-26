import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/services/biometric_attendance_service.dart';

void main() {
  const service = BiometricAttendanceService();
  final sampleBytes = File(
    'test/fixtures/biometric_sample.csv',
  ).readAsBytesSync();

  group('BiometricAttendanceService', () {
    test('extracts first IN and last OUT for employee with punches', () {
      final result = service.processFile(
        bytes: sampleBytes,
        fileName: 'biometric_sample.csv',
      );

      final rituJune1 = result.records.firstWhere(
        (record) =>
            record.employeeId == '001' && record.date == DateTime(2026, 6, 1),
      );

      expect(rituJune1.status, 'HL');
      expect(rituJune1.firstIn, '13:06');
      expect(rituJune1.lastOut, '18:24');
    });

    test('marks Saturday and Sunday as weekoff', () {
      final result = service.processFile(
        bytes: sampleBytes,
        fileName: 'biometric_sample.csv',
      );

      final rituSaturday = result.records.firstWhere(
        (record) =>
            record.employeeId == '001' && record.date == DateTime(2026, 6, 6),
      );
      final rituSunday = result.records.firstWhere(
        (record) =>
            record.employeeId == '001' && record.date == DateTime(2026, 6, 7),
      );

      expect(rituSaturday.status, 'weekoff');
      expect(rituSunday.status, 'weekoff');
      expect(rituSaturday.firstIn, isNull);
      expect(rituSunday.lastOut, isNull);
    });

    test('marks absent when employee has no punches on a weekday', () {
      final result = service.processFile(
        bytes: sampleBytes,
        fileName: 'biometric_sample.csv',
      );

      final rituJune3 = result.records.firstWhere(
        (record) =>
            record.employeeId == '001' && record.date == DateTime(2026, 6, 3),
      );

      expect(rituJune3.status, 'A');
      expect(rituJune3.firstIn, isNull);
      expect(rituJune3.lastOut, isNull);
    });

    test('marks absent for roster employees missing from sheet', () {
      final result = service.processFile(
        bytes: sampleBytes,
        fileName: 'biometric_sample.csv',
      );

      final akankshaJune1 = result.records.firstWhere(
        (record) =>
            record.employeeId == '002' && record.date == DateTime(2026, 6, 1),
      );

      expect(akankshaJune1.employeeName, 'Akanksha');
      expect(akankshaJune1.status, 'A');
    });

    test('exports excel with date sections and attendance columns', () {
      final result = service.processFile(
        bytes: sampleBytes,
        fileName: 'biometric_sample.csv',
      );

      final bytes = service.toExcelBytes(result);
      final workbook = Excel.decodeBytes(bytes);
      final sheet = workbook.tables['Attendance']!;

      expect(sheet.maxRows, greaterThan(5));
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
            .value
            .toString(),
        'Date : 1st June 2026',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
            .value
            .toString(),
        'S.No',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
            .value
            .toString(),
        'Employee Name',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1))
            .value
            .toString(),
        'IN',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1))
            .value
            .toString(),
        'OUT',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1))
            .value
            .toString(),
        'Status',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1))
            .value
            .toString(),
        'Remarks',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
            .value
            .toString(),
        'Mayur',
      );

      final rituRow = _rowWithEmployee(sheet, 'Ritu');
      expect(rituRow, isNotNull);
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rituRow!))
            .value
            .toString(),
        '1:06 PM',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rituRow))
            .value
            .toString(),
        '6:24 PM',
      );
      expect(
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rituRow),
            )
            .value
            .toString(),
        'HL',
      );
    });

    test('exports calculated P, SL, and HL statuses in CSV', () {
      final result = BiometricProcessResult(
        fileName: 'attendance.csv',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 3),
        records: [
          BiometricDailyAttendance(
            employeeId: '001',
            employeeName: 'Present Employee',
            date: DateTime(2026, 6, 1),
            status: 'P',
            firstIn: '09:00',
            lastOut: '17:00',
          ),
          BiometricDailyAttendance(
            employeeId: '002',
            employeeName: 'Short Leave Employee',
            date: DateTime(2026, 6, 2),
            status: 'SL',
            firstIn: '09:00',
            lastOut: '15:00',
          ),
          BiometricDailyAttendance(
            employeeId: '003',
            employeeName: 'Half Day Employee',
            date: DateTime(2026, 6, 3),
            status: 'HL',
            firstIn: '09:00',
            lastOut: '13:00',
          ),
        ],
      );

      final csv = service.toCsv(result);

      expect(csv, contains('Date : 1st June 2026'));
      expect(csv, contains('S.No,Employee Name,IN,OUT,Status,Remarks'));
      expect(csv, contains('1,Present Employee,9:00 AM,5:00 PM,P,'));
      expect(csv, contains('Date : 2nd June 2026'));
      expect(csv, contains('1,Short Leave Employee,9:00 AM,3:00 PM,SL,'));
      expect(csv, contains('Date : 3rd June 2026'));
      expect(csv, contains('1,Half Day Employee,9:00 AM,1:00 PM,HL,'));
      expect(
        service.csvFileName(result),
        'attendance_2026-06-01_to_2026-06-03.csv',
      );
    });

    test('csv and excel list employees in the HR report order', () {
      final date = DateTime(2026, 6, 1);
      final result = BiometricProcessResult(
        fileName: 'attendance.csv',
        periodStart: date,
        periodEnd: date,
        records: [
          BiometricDailyAttendance(
            employeeId: '001',
            employeeName: 'Ritu',
            date: date,
            status: 'P',
            firstIn: '09:00',
            lastOut: '18:00',
          ),
          BiometricDailyAttendance(
            employeeId: '051',
            employeeName: 'Mayur',
            date: date,
            status: 'P',
            firstIn: '09:10',
            lastOut: '18:10',
          ),
          BiometricDailyAttendance(
            employeeId: '074',
            employeeName: 'Baby Jangra',
            date: date,
            status: 'P',
            firstIn: '09:20',
            lastOut: '18:20',
          ),
          BiometricDailyAttendance(
            employeeId: '028',
            employeeName: 'Shouvik Dey',
            date: date,
            status: 'A',
          ),
        ],
      );

      final lines = service
          .toCsv(result)
          .split('\n')
          .where((line) => RegExp(r'^\d+,').hasMatch(line))
          .toList();

      expect(lines, [
        '1,Mayur,9:10 AM,6:10 PM,P,',
        '2,Ritu,9:00 AM,6:00 PM,P,',
        '3,Baby Jangra,9:20 AM,6:20 PM,P,',
        '4,Shouvik Dey,,,A,',
      ]);
    });

    test('processes full biometric export file when available', () {
      final fullFile = File('Create.csv');
      if (!fullFile.existsSync()) {
        return;
      }

      final result = service.processFile(
        bytes: fullFile.readAsBytesSync(),
        fileName: 'Create.csv',
      );

      final rituJune1 = result.records.firstWhere(
        (record) =>
            record.employeeId == '001' && record.date == DateTime(2026, 6, 1),
      );

      expect(rituJune1.firstIn, '13:06');
      expect(rituJune1.lastOut, '18:24');
      expect(result.records.length, greaterThan(1000));
    });

    test('roster report order runs Mayur through Shouvik Dey', () {
      final ordered = [...BiometricEmployeeRoster.employees]..sort(
        (a, b) => BiometricEmployeeRoster.compareReportOrder(
          aName: a.displayName,
          aId: a.normalizedId,
          bName: b.displayName,
          bId: b.normalizedId,
        ),
      );

      expect(
        ordered.map((employee) => employee.displayName).toList(),
        BiometricEmployeeRoster.reportOrder,
      );
    });
  });
}

int? _rowWithEmployee(Sheet sheet, String name) {
  for (var row = 0; row < sheet.maxRows; row++) {
    final value = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value
        ?.toString();
    if (value == name) return row;
  }
  return null;
}

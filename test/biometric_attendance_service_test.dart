import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
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
        '2026-06-01',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
            .value
            .toString(),
        'S.No.',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1))
            .value
            .toString(),
        'IN Time',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
            .value
            .toString(),
        'Ritu',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 2))
            .value
            .toString(),
        '13:06',
      );
      expect(
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2))
            .value
            .toString(),
        '18:24',
      );
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
  });
}

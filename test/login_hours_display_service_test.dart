import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/services/login_hours_display_service.dart';

void main() {
  const service = LoginHoursDisplayService();
  final today = DateTime(2026, 7, 1);
  final yesterday = DateTime(2026, 6, 30);

  final presentRecord = LoginHoursRecord(
    employeeId: '001',
    employeeName: 'Ritu Sharma',
    date: today,
    status: 'P',
    firstIn: '09:15',
    lastOut: '18:30',
  );

  group('LoginHoursDisplayService', () {
    test('shows dash for missing OUT when IN exists', () {
      final record = LoginHoursRecord(
        employeeId: '001',
        employeeName: 'Ritu Sharma',
        date: today,
        status: 'P',
        firstIn: '09:15',
      );
      final result = service.format(
        record: record,
        selectedDate: today,
        today: today,
      );

      expect(result.inTime, '09:15');
      expect(result.outTime, '-');
      expect(result.duration, '-');
      expect(result.status, 'P');
    });

    test('shows first IN, last OUT, and duration for previous dates', () {
      final record = presentRecord.copyWithDate(yesterday);
      final result = service.format(
        record: record,
        selectedDate: yesterday,
        today: today,
      );

      expect(result.inTime, '09:15');
      expect(result.outTime, '18:30');
      expect(result.duration, '9h 15m');
      expect(result.status, 'P');
    });

    test('recomputes incomplete stale half leave as Present', () {
      final stale = LoginHoursRecord(
        employeeId: '003',
        employeeName: 'Akanksha',
        date: yesterday,
        status: 'HL',
        firstIn: '12:03',
      );

      final result = service.format(
        record: stale,
        selectedDate: yesterday,
        today: today,
      );

      expect(result.status, 'P');
    });

    test('recomputes complete day duration to Short Leave', () {
      final record = LoginHoursRecord(
        employeeId: '003',
        employeeName: 'Akanksha',
        date: yesterday,
        status: 'P',
        firstIn: '14:00',
        lastOut: '21:00',
      );

      final result = service.format(
        record: record,
        selectedDate: yesterday,
        today: today,
      );

      expect(result.duration, '7h');
      expect(result.status, 'SL');
    });

    test('keeps manually edited status as stored', () {
      final manual = LoginHoursRecord(
        employeeId: '004',
        employeeName: 'Manual User',
        date: yesterday,
        status: 'HL',
        firstIn: '12:03',
        manuallyEdited: true,
      );

      final result = service.format(
        record: manual,
        selectedDate: yesterday,
        today: today,
      );

      expect(result.status, 'HL');
    });

    test('shows WFH for WFH roster employees without punches', () {
      final wfh = LoginHoursRecord(
        employeeId: '064',
        employeeName: 'Simran',
        date: yesterday,
        status: 'A',
      );

      final result = service.format(
        record: wfh,
        selectedDate: yesterday,
        today: today,
      );

      expect(result.inTime, '-');
      expect(result.outTime, '-');
      expect(result.status, 'WFH');
    });

    test('shows dashes in In/Out and L in Status for leave', () {
      final leave = LoginHoursRecord(
        employeeId: '002',
        employeeName: 'Test User',
        date: yesterday,
        status: 'L',
      );

      final result = service.format(
        record: leave,
        selectedDate: yesterday,
        today: today,
      );

      expect(result.inTime, '-');
      expect(result.outTime, '-');
      expect(result.status, 'L');
    });

    test('shows dashes in In/Out and weekoff in Status for week off', () {
      final weekoff = LoginHoursRecord(
        employeeId: '002',
        employeeName: 'Test User',
        date: yesterday,
        status: 'weekoff',
      );

      final result = service.format(
        record: weekoff,
        selectedDate: yesterday,
        today: today,
      );

      expect(result.inTime, '-');
      expect(result.outTime, '-');
      expect(result.status, 'weekoff');
    });
  });
}

extension on LoginHoursRecord {
  LoginHoursRecord copyWithDate(DateTime date) {
    return copyWith(date: date);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/services/login_hours_sync_service.dart';

void main() {
  const service = LoginHoursSyncService();
  final date = DateTime(2026, 6, 28);

  final incomingComplete = BiometricDailyAttendance(
    employeeId: '001',
    employeeName: 'John',
    date: date,
    status: 'P',
    firstIn: '09:05',
    lastOut: '18:10',
  );

  group('LoginHoursSyncService', () {
    test('creates record when none exists', () {
      final decision = service.decide(
        existing: null,
        incoming: incomingComplete,
      );

      expect(decision.action, LoginHoursSyncAction.create);
      expect(decision.record?.firstIn, '09:05');
      expect(decision.record?.lastOut, '18:10');
    });

    test('skips when complete record already matches the upload', () {
      final existing = LoginHoursRecord(
        employeeId: '001',
        employeeName: 'John',
        date: date,
        status: 'P',
        firstIn: '09:05',
        lastOut: '18:10',
      );

      final decision = service.decide(
        existing: existing,
        incoming: incomingComplete,
      );

      expect(decision.action, LoginHoursSyncAction.skip);
    });

    test('corrects a stored day that was cut short by a mis-tagged punch', () {
      final existing = LoginHoursRecord(
        employeeId: '004',
        employeeName: 'Sukhwinder',
        date: date,
        status: 'A',
        firstIn: '12:03',
        lastOut: '15:12',
      );

      final decision = service.decide(
        existing: existing,
        incoming: BiometricDailyAttendance(
          employeeId: '004',
          employeeName: 'Sukhwinder',
          date: date,
          status: 'P',
          firstIn: '12:03',
          lastOut: '21:01',
        ),
      );

      expect(decision.action, LoginHoursSyncAction.correctSpan);
      expect(decision.record?.firstIn, '12:03');
      expect(decision.record?.lastOut, '21:01');
      expect(decision.record?.status, 'P');
    });

    test('widens a stored day when the upload has an earlier IN', () {
      final existing = LoginHoursRecord(
        employeeId: '001',
        employeeName: 'John',
        date: date,
        status: 'HL',
        firstIn: '14:00',
        lastOut: '18:10',
      );

      final decision = service.decide(
        existing: existing,
        incoming: BiometricDailyAttendance(
          employeeId: '001',
          employeeName: 'John',
          date: date,
          status: 'P',
          firstIn: '09:05',
          lastOut: '18:10',
        ),
      );

      expect(decision.action, LoginHoursSyncAction.correctSpan);
      expect(decision.record?.firstIn, '09:05');
      expect(decision.record?.lastOut, '18:10');
      expect(decision.record?.status, 'P');
    });

    test('never shortens a complete day from a partial re-upload', () {
      final existing = LoginHoursRecord(
        employeeId: '001',
        employeeName: 'John',
        date: date,
        status: 'P',
        firstIn: '09:05',
        lastOut: '20:00',
      );

      final decision = service.decide(
        existing: existing,
        incoming: BiometricDailyAttendance(
          employeeId: '001',
          employeeName: 'John',
          date: date,
          status: 'HL',
          firstIn: '11:00',
          lastOut: '15:30',
        ),
      );

      expect(decision.action, LoginHoursSyncAction.skip);
    });

    test('never corrects a manually overridden day', () {
      final existing = LoginHoursRecord(
        employeeId: '004',
        employeeName: 'Sukhwinder',
        date: date,
        status: 'P',
        firstIn: '12:03',
        lastOut: '15:12',
        manuallyEdited: true,
      );

      final decision = service.decide(
        existing: existing,
        incoming: BiometricDailyAttendance(
          employeeId: '004',
          employeeName: 'Sukhwinder',
          date: date,
          status: 'P',
          firstIn: '12:03',
          lastOut: '21:01',
        ),
      );

      expect(decision.action, LoginHoursSyncAction.skip);
    });

    test('updates only OUT when existing OUT is blank', () {
      final existing = LoginHoursRecord(
        employeeId: '001',
        employeeName: 'John',
        date: date,
        status: 'P',
        firstIn: '09:05',
      );

      final decision = service.decide(
        existing: existing,
        incoming: incomingComplete,
      );

      expect(decision.action, LoginHoursSyncAction.updateOutOnly);
      expect(decision.record?.firstIn, '09:05');
      expect(decision.record?.lastOut, '18:10');
      expect(decision.record?.status, 'P');
    });

    test('preserves IN when completing OUT on next upload', () {
      final existing = LoginHoursRecord(
        employeeId: '001',
        employeeName: 'John',
        date: date,
        status: 'P',
        firstIn: '09:05',
      );

      final incomingWithDifferentIn = BiometricDailyAttendance(
        employeeId: '001',
        employeeName: 'John',
        date: date,
        status: 'P',
        firstIn: '09:10',
        lastOut: '18:10',
      );

      final decision = service.decide(
        existing: existing,
        incoming: incomingWithDifferentIn,
      );

      expect(decision.action, LoginHoursSyncAction.updateOutOnly);
      expect(decision.record?.firstIn, '09:05');
      expect(decision.record?.lastOut, '18:10');
      expect(decision.record?.status, 'P');
    });

    test('skips upload when record was manually edited', () {
      final existing = LoginHoursRecord(
        employeeId: '001',
        employeeName: 'John',
        date: date,
        status: 'P',
        firstIn: '09:00',
        lastOut: '17:00',
        manuallyEdited: true,
      );

      final decision = service.decide(
        existing: existing,
        incoming: incomingComplete,
      );

      expect(decision.action, LoginHoursSyncAction.skip);
    });

    test('skips when OUT blank and upload also has no OUT', () {
      final existing = LoginHoursRecord(
        employeeId: '001',
        employeeName: 'John',
        date: date,
        status: 'P',
        firstIn: '09:05',
      );

      final incomingInOnly = BiometricDailyAttendance(
        employeeId: '001',
        employeeName: 'John',
        date: date,
        status: 'P',
        firstIn: '09:05',
      );

      final decision = service.decide(
        existing: existing,
        incoming: incomingInOnly,
      );

      expect(decision.action, LoginHoursSyncAction.skip);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/services/attendance_calendar_merge_service.dart';

void main() {
  const service = AttendanceCalendarMergeService();

  LoginHoursRecord loginHours({
    required DateTime date,
    String status = '',
    String? firstIn,
    String? lastOut,
    bool manuallyEdited = false,
  }) {
    return LoginHoursRecord(
      employeeId: '001',
      employeeName: 'Ritu',
      date: date,
      status: status,
      firstIn: firstIn,
      lastOut: lastOut,
      manuallyEdited: manuallyEdited,
    );
  }

  List<AttendanceRecord> mergeFor({
    List<AttendanceRecord> stored = const [],
    List<LoginHoursRecord> hours = const [],
    DateTime? today,
  }) {
    return service.merge(
      employeeName: 'Ritu Sharma',
      employeeEmail: 'ritu.sharma@caglobal.com',
      stored: stored,
      loginHours: hours,
      today: today ?? DateTime(2026, 8, 14),
    );
  }

  group('AttendanceCalendarMergeService', () {
    test('marks a day with a login time as Present', () {
      final merged = mergeFor(
        hours: [loginHours(date: DateTime(2026, 8, 11), firstIn: '11:07')],
      );

      expect(merged.single.status, 'P');
      expect(merged.single.date, DateTime(2026, 8, 11));
      expect(merged.single.employeeEmail, 'ritu.sharma@caglobal.com');
    });

    test('marks a day without any punch as Absent', () {
      final merged = mergeFor(
        hours: [loginHours(date: DateTime(2026, 8, 10), status: 'A')],
      );

      expect(merged.single.status, 'A');
    });

    test('marks WFH employees without punches as WFH', () {
      final merged = mergeFor(
        hours: [
          LoginHoursRecord(
            employeeId: '064',
            employeeName: 'Simran',
            date: DateTime(2026, 8, 11),
            status: 'A',
          ),
        ],
      );

      expect(merged.single.status, 'WFH');
    });

    test('recomputes incomplete stale half leave as Present', () {
      final merged = mergeFor(
        hours: [
          loginHours(
            date: DateTime(2026, 8, 11),
            status: 'HL',
            firstIn: '12:03',
          ),
        ],
      );

      expect(merged.single.status, 'P');
    });

    test('marks short leave from first IN to last OUT duration', () {
      final merged = mergeFor(
        hours: [
          loginHours(
            date: DateTime(2026, 8, 11),
            status: 'P',
            firstIn: '14:00',
            lastOut: '21:00',
          ),
        ],
      );

      expect(merged.single.status, 'SL');
    });

    test('marks half day from first IN to last OUT duration', () {
      final merged = mergeFor(
        hours: [
          loginHours(
            date: DateTime(2026, 8, 11),
            status: 'P',
            firstIn: '17:00',
            lastOut: '21:00',
          ),
        ],
      );

      expect(merged.single.status, 'HL');
    });

    test('marks absent when duration is under 4 hours', () {
      final merged = mergeFor(
        hours: [
          loginHours(
            date: DateTime(2026, 8, 11),
            status: 'P',
            firstIn: '15:30',
            lastOut: '15:33',
          ),
        ],
      );

      expect(merged.single.status, 'A');
    });

    test('skips weekoff and empty days', () {
      final merged = mergeFor(
        hours: [
          loginHours(date: DateTime(2026, 8, 8), status: 'weekoff'),
          loginHours(date: DateTime(2026, 8, 9), status: 'weekoff'),
          loginHours(date: DateTime(2026, 8, 12)),
        ],
      );

      expect(merged, isEmpty);
    });

    test('keeps sheet leave over a biometric absence on the same day', () {
      final date = DateTime(2026, 8, 10);
      final merged = mergeFor(
        stored: [
          AttendanceRecord(
            employeeName: 'Ritu Sharma',
            employeeEmail: 'ritu.sharma@caglobal.com',
            date: date,
            status: 'L',
          ),
        ],
        hours: [loginHours(date: date, status: 'A')],
      );

      expect(merged.single.status, 'L');
    });

    test('login hours win over a stale sheet status', () {
      final date = DateTime(2026, 8, 11);
      final merged = mergeFor(
        stored: [
          AttendanceRecord(
            employeeName: 'Ritu Sharma',
            employeeEmail: 'ritu.sharma@caglobal.com',
            date: date,
            status: 'A',
          ),
        ],
        hours: [loginHours(date: date, firstIn: '11:07', lastOut: '20:15')],
      );

      expect(merged.single.status, 'P');
    });

    test('keeps sheet days that have no login hours record', () {
      final merged = mergeFor(
        stored: [
          AttendanceRecord(
            employeeName: 'Ritu Sharma',
            employeeEmail: 'ritu.sharma@caglobal.com',
            date: DateTime(2026, 7, 1),
            status: 'P',
          ),
        ],
      );

      expect(merged.single.date, DateTime(2026, 7, 1));
    });

    test('respects a manual status edit', () {
      final merged = mergeFor(
        hours: [
          loginHours(
            date: DateTime(2026, 8, 11),
            status: 'HL',
            firstIn: '11:07',
            manuallyEdited: true,
          ),
        ],
      );

      expect(merged.single.status, 'HL');
    });

    test('returns days in date order', () {
      final merged = mergeFor(
        hours: [
          loginHours(date: DateTime(2026, 8, 11), firstIn: '11:07'),
          loginHours(date: DateTime(2026, 8, 10), status: 'A'),
        ],
      );

      expect(merged.map((record) => record.date.day), [10, 11]);
    });

    test('hides upcoming dates so they stay a blank calendar', () {
      final merged = mergeFor(
        hours: [
          loginHours(date: DateTime(2026, 8, 14), status: 'A'),
          loginHours(date: DateTime(2026, 8, 15), status: 'A'),
          loginHours(
            date: DateTime(2026, 8, 16),
            status: 'A',
            firstIn: '12:00',
            lastOut: '21:00',
          ),
        ],
        stored: [
          AttendanceRecord(
            employeeName: 'Ritu Sharma',
            employeeEmail: 'ritu.sharma@caglobal.com',
            date: DateTime(2026, 8, 20),
            status: 'A',
          ),
        ],
        today: DateTime(2026, 8, 14),
      );

      expect(merged.single.date, DateTime(2026, 8, 14));
      expect(merged.single.status, 'A');
    });
  });

  group('BiometricEmployeeRoster.findByEmployeeName', () {
    test('matches a full portal name to the roster first name', () {
      expect(
        BiometricEmployeeRoster.findByEmployeeName('Ritu Sharma')?.normalizedId,
        '001',
      );
    });

    test('matches Simran Mehra and WFH-labelled names to Simran', () {
      final byFull = BiometricEmployeeRoster.findByEmployeeName('Simran Mehra');
      final byLabel = BiometricEmployeeRoster.findByEmployeeName(
        'Simran Mehra (WFH)',
      );

      expect(byFull?.normalizedId, '064');
      expect(byFull?.isWfh, isTrue);
      expect(byFull?.displayName, 'Simran (WFH)');
      expect(byLabel?.normalizedId, '064');
    });

    test('does not include Kamal in the roster', () {
      expect(BiometricEmployeeRoster.findById('007'), isNull);
      expect(BiometricEmployeeRoster.findByEmployeeName('Kamal'), isNull);
    });

    test('matches an exact roster name', () {
      expect(
        BiometricEmployeeRoster.findByEmployeeName(
          'Kawaldeep Kaur',
        )?.normalizedId,
        '069',
      );
    });

    test('returns null for an unknown name', () {
      expect(BiometricEmployeeRoster.findByEmployeeName('Nobody Here'), isNull);
    });

    test('returns null for a blank name', () {
      expect(BiometricEmployeeRoster.findByEmployeeName('   '), isNull);
    });
  });
}

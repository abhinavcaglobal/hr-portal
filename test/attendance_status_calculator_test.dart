import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/services/attendance_status_calculator.dart';

void main() {
  const calculator = AttendanceStatusCalculator();

  group('AttendanceStatusCalculator arrivalStatus', () {
    test('marks on-time arrivals as Present', () {
      expect(calculator.arrivalStatus('11:30'), AttendanceStatus.present);
      expect(calculator.arrivalStatus('12:00'), AttendanceStatus.present);
      expect(calculator.arrivalStatus('12:10'), AttendanceStatus.present);
      expect(calculator.arrivalStatus('14:31'), AttendanceStatus.present);
      expect(calculator.arrivalStatus('16:00'), AttendanceStatus.present);
    });

    test('marks 12:11–12:30 arrivals as Late Punch', () {
      expect(calculator.arrivalStatus('12:11'), AttendanceStatus.latePunch);
      expect(calculator.arrivalStatus('12:20'), AttendanceStatus.latePunch);
      expect(calculator.arrivalStatus('12:30'), AttendanceStatus.latePunch);
    });
  });

  group('AttendanceStatusCalculator departureStatus', () {
    test('marks any departure time as Present', () {
      expect(calculator.departureStatus('14:30'), AttendanceStatus.present);
      expect(calculator.departureStatus('17:00'), AttendanceStatus.present);
      expect(calculator.departureStatus('18:00'), AttendanceStatus.present);
      expect(calculator.departureStatus('20:00'), AttendanceStatus.present);
      expect(calculator.departureStatus('21:00'), AttendanceStatus.present);
    });
  });

  group('AttendanceStatusCalculator calculate — duration rules', () {
    test('marks Absent when both IN and OUT are missing', () {
      expect(
        calculator.calculate(firstIn: null, lastOut: null),
        AttendanceStatus.absent,
      );
      expect(
        calculator.calculate(firstIn: '', lastOut: '  '),
        AttendanceStatus.absent,
      );
    });

    test('Test 1: 12:00 → 21:00 (9h) is Present', () {
      expect(
        calculator.calculate(firstIn: '12:00', lastOut: '21:00'),
        AttendanceStatus.present,
      );
    });

    test('Test 2: 14:00 → 21:00 (7h) is Short Leave', () {
      expect(
        calculator.calculate(firstIn: '14:00', lastOut: '21:00'),
        AttendanceStatus.shortLeave,
      );
    });

    test('Test 3: 17:00 → 21:00 (4h) is Half Day', () {
      expect(
        calculator.calculate(firstIn: '17:00', lastOut: '21:00'),
        AttendanceStatus.halfLeave,
      );
    });

    test('Test 4: 15:30 → 15:33 (3m) is Absent', () {
      expect(
        calculator.calculate(firstIn: '15:30', lastOut: '15:33'),
        AttendanceStatus.absent,
      );
    });

    test('Test 5: 11:00 → 20:00 (9h) is Present', () {
      expect(
        calculator.calculate(firstIn: '11:00', lastOut: '20:00'),
        AttendanceStatus.present,
      );
    });

    test('Test 6: 11:09 → 20:00 (8h 51m) is Present', () {
      expect(
        calculator.calculate(firstIn: '11:09', lastOut: '20:00'),
        AttendanceStatus.present,
      );
      expect(
        calculator.formatDuration(firstIn: '11:09', lastOut: '20:00'),
        '8h 51m',
      );
    });

    test('Test 7: 16:50 → 21:01 (4h 11m) is Half Day', () {
      expect(
        calculator.calculate(firstIn: '16:50', lastOut: '21:01'),
        AttendanceStatus.halfLeave,
      );
    });

    test('Test 8: multi-punch span 11:09 → 20:00 is Present', () {
      // Callers supply earliest IN and latest OUT only.
      expect(
        calculator.calculate(firstIn: '11:09', lastOut: '20:00'),
        AttendanceStatus.present,
      );
      expect(
        calculator.durationMinutes(firstIn: '11:09', lastOut: '20:00'),
        8 * 60 + 51,
      );
    });

    test('marks Present for exactly 8 hours when IN is before late window', () {
      expect(
        calculator.calculate(firstIn: '12:10', lastOut: '20:10'),
        AttendanceStatus.present,
      );
    });

    test('marks Late Punch when first IN is 12:11 and duration >= 8h', () {
      expect(
        calculator.calculate(firstIn: '12:11', lastOut: '21:00'),
        AttendanceStatus.latePunch,
      );
    });

    test('marks Late Punch when first IN is 12:30 and duration >= 8h', () {
      expect(
        calculator.calculate(firstIn: '12:30', lastOut: '21:00'),
        AttendanceStatus.latePunch,
      );
    });

    test('marks Late Punch for mid-window arrival with full duration', () {
      expect(
        calculator.calculate(firstIn: '12:20', lastOut: '21:00'),
        AttendanceStatus.latePunch,
      );
    });

    test('keeps Short Leave over Late Punch when duration is under 8h', () {
      expect(
        calculator.calculate(firstIn: '12:15', lastOut: '19:00'),
        AttendanceStatus.shortLeave,
      );
    });

    test('marks Late Punch for incomplete day with late first IN', () {
      expect(
        calculator.calculate(firstIn: '12:15', lastOut: null),
        AttendanceStatus.latePunch,
      );
    });

    test('marks Short Leave for 7h 30m', () {
      expect(
        calculator.calculate(firstIn: '12:00', lastOut: '19:30'),
        AttendanceStatus.shortLeave,
      );
    });

    test('marks Short Leave at exactly 6 hours', () {
      expect(
        calculator.calculate(firstIn: '12:00', lastOut: '18:00'),
        AttendanceStatus.shortLeave,
      );
    });

    test('marks Half Day just under 6 hours', () {
      expect(
        calculator.calculate(firstIn: '12:00', lastOut: '17:59'),
        AttendanceStatus.halfLeave,
      );
    });

    test('marks Absent just under 4 hours', () {
      expect(
        calculator.calculate(firstIn: '12:00', lastOut: '15:59'),
        AttendanceStatus.absent,
      );
    });

    test('keeps Present when only early IN is present (incomplete)', () {
      expect(
        calculator.calculate(firstIn: '12:00', lastOut: null),
        AttendanceStatus.present,
      );
    });

    test('keeps Present when only OUT is present (incomplete)', () {
      expect(
        calculator.calculate(firstIn: null, lastOut: '17:00'),
        AttendanceStatus.present,
      );
    });
  });

  group('AttendanceStatusCalculator formatDuration', () {
    test('formats hours and minutes', () {
      expect(
        calculator.formatDuration(firstIn: '11:09', lastOut: '20:00'),
        '8h 51m',
      );
      expect(
        calculator.formatDuration(firstIn: '12:00', lastOut: '21:00'),
        '9h',
      );
      expect(
        calculator.formatDuration(firstIn: '15:30', lastOut: '15:33'),
        '3m',
      );
    });

    test('returns dash when incomplete', () {
      expect(calculator.formatDuration(firstIn: '12:00', lastOut: null), '-');
      expect(calculator.formatDuration(firstIn: null, lastOut: '18:00'), '-');
    });
  });

  group('AttendanceStatus.moreSevere', () {
    test('picks the more severe status', () {
      expect(
        AttendanceStatus.moreSevere(
          AttendanceStatus.present,
          AttendanceStatus.latePunch,
        ),
        AttendanceStatus.latePunch,
      );
      expect(
        AttendanceStatus.moreSevere(
          AttendanceStatus.latePunch,
          AttendanceStatus.shortLeave,
        ),
        AttendanceStatus.shortLeave,
      );
      expect(
        AttendanceStatus.moreSevere(
          AttendanceStatus.shortLeave,
          AttendanceStatus.halfLeave,
        ),
        AttendanceStatus.halfLeave,
      );
      expect(
        AttendanceStatus.moreSevere(
          AttendanceStatus.present,
          AttendanceStatus.present,
        ),
        AttendanceStatus.present,
      );
    });
  });
}

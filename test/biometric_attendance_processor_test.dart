import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/services/biometric_attendance_processor.dart';
import 'package:hr_portal/services/biometric_sheet_parser.dart';

void main() {
  const processor = BiometricAttendanceProcessor();
  final date = DateTime(2026, 7, 1);

  BiometricPunch punch(String time, {required bool isIn}) {
    return BiometricPunch(
      employeeId: '004',
      employeeName: 'Sukhwinder',
      date: date,
      time: time,
      isIn: isIn,
      isOut: !isIn,
    );
  }

  BiometricDailyAttendance runFor(List<BiometricPunch> punches) {
    final result = processor.process(
      fileName: 'test.csv',
      today: DateTime(2026, 7, 1),
      parsed: BiometricSheetParseResult(
        periodStart: date,
        periodEnd: date,
        punches: punches,
      ),
    );

    return result.records.firstWhere(
      (record) => record.employeeId == '004' && record.date == date,
    );
  }

  group('BiometricAttendanceProcessor upcoming dates', () {
    test('does not mark dates after today as Absent', () {
      final today = DateTime(2026, 8, 14);
      final result = processor.process(
        fileName: 'test.csv',
        today: today,
        parsed: BiometricSheetParseResult(
          periodStart: DateTime(2026, 8, 13),
          periodEnd: DateTime(2026, 8, 16),
          punches: [
            BiometricPunch(
              employeeId: '004',
              employeeName: 'Sukhwinder',
              date: DateTime(2026, 8, 13),
              time: '12:00',
              isIn: true,
              isOut: false,
            ),
            BiometricPunch(
              employeeId: '004',
              employeeName: 'Sukhwinder',
              date: DateTime(2026, 8, 13),
              time: '21:00',
              isIn: false,
              isOut: true,
            ),
          ],
        ),
      );

      final sukhwinder = result.records.where(
        (record) => record.employeeId == '004',
      );
      expect(
        sukhwinder.map((record) => record.date.day).toList(),
        [13, 14],
      );
      expect(
        sukhwinder.any((record) => record.date.day > 14),
        isFalse,
      );
    });
  });

  group('BiometricAttendanceProcessor day span', () {
    test('uses first IN and last OUT across multiple punches', () {
      final record = runFor([
        punch('11:09', isIn: true),
        punch('15:12', isIn: false),
        punch('15:13', isIn: true),
        punch('18:28', isIn: false),
        punch('18:38', isIn: true),
        punch('20:00', isIn: false),
      ]);

      expect(record.firstIn, '11:09');
      expect(record.lastOut, '20:00');
      expect(record.status, 'P');
    });

    test('closing punch mis-tagged as IN still ends the day', () {
      final record = runFor([
        punch('12:03', isIn: true),
        punch('15:12', isIn: false),
        punch('15:20', isIn: true),
        punch('21:01', isIn: true),
      ]);

      expect(record.firstIn, '12:03');
      expect(record.lastOut, '21:01');
      expect(record.status, 'P');
    });

    test('opening punch mis-tagged as OUT still starts the day', () {
      final record = runFor([
        punch('11:59', isIn: false),
        punch('12:30', isIn: true),
        punch('21:00', isIn: false),
      ]);

      expect(record.firstIn, '11:59');
      expect(record.lastOut, '21:00');
      expect(record.status, 'P');
    });

    test('never shortens a day that already ends with the last OUT', () {
      final record = runFor([
        punch('17:00', isIn: true),
        punch('21:00', isIn: false),
      ]);

      expect(record.firstIn, '17:00');
      expect(record.lastOut, '21:00');
      expect(record.status, 'HL');
    });

    test('leaves OUT missing when no OUT punch exists at all', () {
      final record = runFor([
        punch('12:03', isIn: true),
        punch('21:01', isIn: true),
      ]);

      expect(record.firstIn, '12:03');
      expect(record.lastOut, isNull);
      expect(record.status, 'P');
    });

    test('short genuine day is still Absent', () {
      final record = runFor([
        punch('15:30', isIn: true),
        punch('15:33', isIn: false),
      ]);

      expect(record.firstIn, '15:30');
      expect(record.lastOut, '15:33');
      expect(record.status, 'A');
    });
  });
}

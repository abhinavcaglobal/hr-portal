import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/models/attendance_month_note.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/services/monthly_attendance_matrix_builder.dart';

void main() {
  const builder = MonthlyAttendanceMatrixBuilder();

  group('MonthlyAttendanceMatrixBuilder', () {
    test('builds day columns with weekdays for the month', () {
      final matrix = builder.build(
        year: 2026,
        month: 6,
        employeeNames: const ['Mayur Kumar'],
        records: const [],
        notes: const [],
      );

      expect(matrix.dayColumns, hasLength(30));
      expect(matrix.monthLabel, 'June');
      expect(matrix.dayColumns.first.day, 1);
      expect(matrix.dayColumns.first.weekdayLabel, 'Mon');
      expect(matrix.dayColumns[5].day, 6);
      expect(matrix.dayColumns[5].weekdayLabel, 'Sat');
      expect(matrix.dayColumns.last.day, 30);
    });

    test('merges statuses by normalized employee name and day', () {
      final matrix = builder.build(
        year: 2026,
        month: 6,
        employeeNames: const ['Simran Mehra (WFH)', 'Mayur Kumar'],
        records: [
          AttendanceRecord(
            employeeName: 'Simran Mehra',
            date: DateTime(2026, 6, 1),
            status: 'WFH',
          ),
          AttendanceRecord(
            employeeName: 'Mayur Kumar',
            date: DateTime(2026, 6, 2),
            status: 'p',
          ),
          AttendanceRecord(
            employeeName: 'Mayur Kumar',
            date: DateTime(2026, 5, 2),
            status: 'L',
          ),
        ],
        notes: const [
          AttendanceMonthNote(
            employeeName: 'Mayur Kumar',
            year: 2026,
            month: 6,
            remarks: 'On leave later',
            reference: 'Note A',
          ),
        ],
        today: DateTime(2026, 6, 2),
      );

      expect(matrix.rows, hasLength(2));
      expect(matrix.rows[0].employeeName, 'Simran Mehra (WFH)');
      expect(matrix.rows[0].statusForDay(1), 'WFH');
      expect(matrix.rows[1].statusForDay(2), 'P');
      // Past weekday with no record defaults to Absent.
      expect(matrix.rows[1].statusForDay(1), 'A');
      expect(matrix.rows[1].remarks, 'On leave later');
      expect(matrix.rows[1].reference, 'Note A');
    });

    test('normalizeEmployeeName strips parenthetical suffixes', () {
      expect(
        MonthlyAttendanceMatrixBuilder.normalizeEmployeeName(
          'Simran Mehra (WFH)',
        ),
        'simran mehra',
      );
      expect(
        MonthlyAttendanceMatrixBuilder.normalizeEmployeeName('  Mayur   Kumar '),
        'mayur kumar',
      );
    });

    test('merges biometric short names into full portal rows', () {
      final matrix = builder.build(
        year: 2026,
        month: 9,
        employeeNames: const [
          'Armaanpreet kaur',
          'Yashpal Thakur',
          'Gurpreet Singh Sidhu',
        ],
        records: [
          AttendanceRecord(
            employeeName: 'Armaan',
            date: DateTime(2026, 9, 1),
            status: 'P',
          ),
          AttendanceRecord(
            employeeName: 'Yashpal',
            date: DateTime(2026, 9, 1),
            status: 'P',
          ),
          AttendanceRecord(
            employeeName: 'Gurpreet',
            date: DateTime(2026, 9, 2),
            status: 'A',
          ),
        ],
        notes: const [],
        today: DateTime(2026, 9, 2),
      );

      expect(matrix.rows[0].statusForDay(1), 'P');
      expect(matrix.rows[1].statusForDay(1), 'P');
      expect(matrix.rows[2].statusForDay(2), 'A');
    });

    test('maps Rajeev biometric records onto Rajiv Kumar without email', () {
      final matrix = builder.build(
        year: 2026,
        month: 8,
        employeeNames: const ['Rajiv Kumar'],
        records: [
          AttendanceRecord(
            employeeName: 'Rajeev',
            date: DateTime(2026, 8, 3),
            status: 'P',
          ),
          AttendanceRecord(
            employeeName: 'Rajeev',
            date: DateTime(2026, 8, 4),
            status: 'HL',
          ),
          AttendanceRecord(
            employeeName: 'Rajeev',
            date: DateTime(2026, 8, 5),
            status: 'SL',
          ),
          AttendanceRecord(
            employeeName: 'Rajeev',
            date: DateTime(2026, 8, 6),
            status: 'LP',
          ),
        ],
        notes: const [
          AttendanceMonthNote(
            employeeName: 'Rajiv Kumar',
            year: 2026,
            month: 8,
            remarks: 'Office boy',
            reference: 'Gate',
          ),
        ],
        today: DateTime(2026, 8, 6),
      );

      expect(matrix.rows.single.statusForDay(3), 'P');
      expect(matrix.rows.single.statusForDay(4), 'HL');
      expect(matrix.rows.single.statusForDay(5), 'SL');
      expect(matrix.rows.single.statusForDay(6), 'LP');
      expect(matrix.rows.single.remarks, 'Office boy');
      expect(matrix.rows.single.reference, 'Gate');
      // Weekend stays blank.
      expect(matrix.rows.single.statusForDay(1), isEmpty);
      expect(matrix.rows.single.statusForDay(2), isEmpty);
    });

    test('leaves future weekdays blank', () {
      final matrix = builder.build(
        year: 2026,
        month: 9,
        employeeNames: const ['Mayur Kumar'],
        records: const [],
        notes: const [],
        today: DateTime(2026, 9, 4),
      );

      expect(matrix.rows.single.statusForDay(3), 'A');
      expect(matrix.rows.single.statusForDay(4), 'A');
      expect(matrix.rows.single.statusForDay(5), isEmpty);
    });
  });
}

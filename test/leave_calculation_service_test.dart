import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/services/leave_calculation_service.dart';

void main() {
  const service = LeaveCalculationService();

  AttendanceRecord leaveOn(DateTime date, String status) =>
      AttendanceRecord(employeeName: 'Test', date: date, status: status);

  group('LeaveCalculationService', () {
    test('deductions match status rules', () {
      expect(service.deductionForStatus('P'), 0);
      expect(service.deductionForStatus('L'), 1.0);
      expect(service.deductionForStatus('HL'), 0.5);
      expect(service.deductionForStatus('SL'), 0.25);
      expect(service.deductionForStatus('UL'), 0);
    });

    group(
      'monthly carry-forward examples (opening balance through May 2026 = 1)',
      () {
        const openingBalance = 1.0;
        final asOfJuly = DateTime(2026, 7, 1);

        test('example 1: no leave taken in June', () {
          final balance = service.calculateCurrentBalance(
            openingBalance: openingBalance,
            attendanceRecords: const [],
            asOfDate: asOfJuly,
          );

          expect(balance, 2.0);
        });

        test('example 2: full-day leave taken in June', () {
          final balance = service.calculateCurrentBalance(
            openingBalance: openingBalance,
            attendanceRecords: [leaveOn(DateTime(2026, 6, 15), 'L')],
            asOfDate: asOfJuly,
          );

          expect(balance, 1.0);
        });

        test('example 3: half-day leave taken in June', () {
          final balance = service.calculateCurrentBalance(
            openingBalance: openingBalance,
            attendanceRecords: [leaveOn(DateTime(2026, 6, 15), 'HL')],
            asOfDate: asOfJuly,
          );

          expect(balance, 1.5);
        });

        test('example 4: short leave taken in June', () {
          final balance = service.calculateCurrentBalance(
            openingBalance: openingBalance,
            attendanceRecords: [leaveOn(DateTime(2026, 6, 15), 'SL')],
            asOfDate: asOfJuly,
          );

          expect(balance, 1.75);
        });
      },
    );

    test('returns opening balance through end of May 2026', () {
      final balance = service.calculateCurrentBalance(
        openingBalance: 3,
        attendanceRecords: [leaveOn(DateTime(2026, 5, 15), 'L')],
        asOfDate: DateTime(2026, 5, 31),
      );

      expect(balance, 3);
    });

    test(
      'completed months accrue and current-month leave deducts immediately',
      () {
        final records = [
          leaveOn(DateTime(2026, 8, 1), 'L'),
          leaveOn(DateTime(2026, 8, 2), 'HL'),
        ];

        final balance = service.calculateCurrentBalance(
          openingBalance: 5,
          attendanceRecords: records,
          asOfDate: DateTime(2026, 9, 15),
        );

        // 5 opening + Jun (1) + Jul (1) + Aug unused (0) - Aug excess (0.5) = 6.5
        expect(balance, 6.5);
      },
    );

    test(
      'current-month leave reduces balance before entitlement is earned',
      () {
        final balance = service.calculateCurrentBalance(
          openingBalance: 2,
          attendanceRecords: [leaveOn(DateTime(2026, 8, 20), 'HL')],
          asOfDate: DateTime(2026, 8, 31),
        );

        // 2 opening + Jun (1) + Jul (1) - Aug leave so far (0.5) = 3.5
        expect(balance, 3.5);
      },
    );

    test(
      'leave beyond monthly entitlement deducts from accumulated balance',
      () {
        final balance = service.calculateCurrentBalance(
          openingBalance: 1,
          attendanceRecords: [
            leaveOn(DateTime(2026, 6, 1), 'L'),
            leaveOn(DateTime(2026, 6, 2), 'L'),
          ],
          asOfDate: DateTime(2026, 7, 1),
        );

        // Jun: +0 unused entitlement, -1 excess leave
        expect(balance, 0.0);
      },
    );

    test('completed months is zero at start of accrual cycle', () {
      final months = service.completedMonthsSinceAccrual(DateTime(2026, 6, 1));
      expect(months, 0);
    });

    test('returns opening balance on the first day of the accrual cycle', () {
      final balance = service.calculateCurrentBalance(
        openingBalance: 3,
        attendanceRecords: const [],
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(balance, 3);
    });

    test(
      'deducts current-month leave on the first day of the accrual cycle',
      () {
        final balance = service.calculateCurrentBalance(
          openingBalance: 3,
          attendanceRecords: [leaveOn(DateTime(2026, 6, 1), 'L')],
          asOfDate: DateTime(2026, 6, 1),
        );

        expect(balance, 2);
      },
    );
  });
}

import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/models/attendance_record.dart';

/// Calculates employee leave balance from an opening balance (through end of May),
/// monthly entitlements from June onward, and per-month carry-forward rules.
class LeaveCalculationService {
  const LeaveCalculationService();

  static const double monthlyEntitlement = 1.0;

  /// Pending leave balance as of [asOfDate]:
  ///
  /// 1. Start with the uploaded opening balance (through end of May).
  /// 2. For each completed month from June through the previous calendar month,
  ///    add the unused portion of that month's entitlement (1 leave per month).
  ///    Leave taken in a month is applied against that month's entitlement first;
  ///    any excess is deducted from the accumulated balance.
  /// 3. For the current calendar month, deduct leave taken so far against the
  ///    accumulated balance (that month's entitlement is not earned until the
  ///    month is complete).
  double calculateCurrentBalance({
    required double openingBalance,
    required List<AttendanceRecord> attendanceRecords,
    DateTime? asOfDate,
  }) {
    final referenceDate = asOfDate ?? DateTime.now();
    final cycleStart = _leaveCycleStartDate(referenceDate);
    final currentMonthStart = DateTime(
      referenceDate.year,
      referenceDate.month,
      1,
    );

    if (currentMonthStart.isBefore(cycleStart)) {
      return openingBalance;
    }

    final cycleAttendance = attendanceRecords
        .where((record) => !record.date.isBefore(cycleStart))
        .toList();

    var balance = openingBalance;
    var month = cycleStart;

    while (month.isBefore(currentMonthStart)) {
      final leaveTaken = leaveTakenInMonth(
        cycleAttendance,
        year: month.year,
        month: month.month,
      );
      balance = _applyCompletedMonth(balance, leaveTaken);
      month = DateTime(month.year, month.month + 1, 1);
    }

    final currentMonthLeave = leaveTakenInMonth(
      cycleAttendance,
      year: referenceDate.year,
      month: referenceDate.month,
    );
    balance -= currentMonthLeave;

    return balance;
  }

  /// Applies one completed month's entitlement and leave usage.
  ///
  /// Unused monthly entitlement is carried forward; leave beyond the monthly
  /// entitlement is deducted from the accumulated balance.
  double _applyCompletedMonth(double balance, double leaveTaken) {
    final fromEntitlement = leaveTaken.clamp(0.0, monthlyEntitlement);
    final unusedEntitlement = monthlyEntitlement - fromEntitlement;
    final excessLeave = leaveTaken > monthlyEntitlement
        ? leaveTaken - monthlyEntitlement
        : 0.0;

    return balance + unusedEntitlement - excessLeave;
  }

  /// Sums leave deductions for attendance records in the given calendar month.
  double leaveTakenInMonth(
    List<AttendanceRecord> records, {
    required int year,
    required int month,
  }) {
    return records
        .where(
          (record) => record.date.year == year && record.date.month == month,
        )
        .fold<double>(
          0,
          (sum, record) => sum + AttendanceStatus.deductionFor(record.status),
        );
  }

  /// Counts full calendar months completed since the June accrual start of the
  /// current leave cycle (up to the end of the previous month).
  int completedMonthsSinceAccrual(DateTime asOfDate) {
    final cycleStart = _leaveCycleStartDate(asOfDate);
    final endOfPreviousMonth = DateTime(asOfDate.year, asOfDate.month, 0);

    if (endOfPreviousMonth.isBefore(cycleStart)) {
      return 0;
    }

    final months =
        (endOfPreviousMonth.year - cycleStart.year) * 12 +
        (endOfPreviousMonth.month - cycleStart.month) +
        1;

    return months.clamp(0, 12);
  }

  DateTime _leaveCycleStartDate(DateTime asOfDate) {
    final accrualMonth = AppConstants.leaveCycleStartMonth;
    final firstAccrual = DateTime(
      AppConstants.firstAccrualYear,
      accrualMonth,
      1,
    );

    if (asOfDate.isBefore(firstAccrual)) {
      return firstAccrual;
    }

    if (asOfDate.month >= accrualMonth) {
      return DateTime(asOfDate.year, accrualMonth, 1);
    }

    return DateTime(asOfDate.year - 1, accrualMonth, 1);
  }

  double totalLeaveDeductions(List<AttendanceRecord> records) {
    return records.fold<double>(
      0,
      (sum, record) => sum + AttendanceStatus.deductionFor(record.status),
    );
  }

  double deductionForStatus(String status) =>
      AttendanceStatus.deductionFor(status);
}

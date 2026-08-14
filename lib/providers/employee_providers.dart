import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/repository_providers.dart';

final employeeProvider = FutureProvider((ref) async {
  return ref.watch(currentEmployeeProvider.future);
});

final selectedEmployeeEmailProvider = Provider<String?>((ref) {
  final employee = ref.watch(currentEmployeeProvider).valueOrNull;
  final email = employee?.email;
  if (email == null || email.trim().isEmpty) {
    return null;
  }
  return email.trim().toLowerCase();
});

final leaveBalanceProvider = FutureProvider<double>((ref) async {
  final employee = await ref.watch(currentEmployeeProvider.future);
  if (employee == null || employee.email.trim().isEmpty) {
    return 0;
  }

  final attendanceRepo = ref.read(attendanceRepositoryProvider);
  final leaveService = ref.read(leaveCalculationServiceProvider);
  final attendance = await attendanceRepo.getAllAttendanceForEmployeeEmail(
    employee.email,
  );

  return leaveService.calculateCurrentBalance(
    openingBalance: employee.openingBalance,
    attendanceRecords: attendance,
  );
});

class AttendanceMonthParams {
  const AttendanceMonthParams({required this.year, required this.month});

  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceMonthParams &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => Object.hash(year, month);
}

final monthlyAttendanceProvider =
    FutureProvider.family<List<AttendanceRecord>, AttendanceMonthParams>((
      ref,
      params,
    ) async {
      final email = ref.watch(selectedEmployeeEmailProvider);
      if (email == null) {
        return [];
      }

      final stored = await ref
          .read(attendanceRepositoryProvider)
          .getAttendanceForMonth(
            employeeEmail: email,
            year: params.year,
            month: params.month,
          );

      final employee = await ref.watch(currentEmployeeProvider.future);
      final rosterEntry = employee == null
          ? null
          : BiometricEmployeeRoster.findByEmployeeName(employee.name);

      if (rosterEntry == null) {
        return stored;
      }

      final loginHours = await ref
          .read(loginHoursRepositoryProvider)
          .getRecordsForEmployeeMonth(
            employeeId: rosterEntry.normalizedId,
            year: params.year,
            month: params.month,
          );

      return ref
          .read(attendanceCalendarMergeServiceProvider)
          .merge(
            employeeName: employee!.name,
            employeeEmail: email,
            stored: stored,
            loginHours: loginHours,
          );
    });

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

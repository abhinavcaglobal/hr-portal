import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/repositories/admin_repository.dart';
import 'package:hr_portal/repositories/attendance_repository.dart';
import 'package:hr_portal/repositories/employee_repository.dart';
import 'package:hr_portal/repositories/holiday_calendar_repository.dart';
import 'package:hr_portal/repositories/leave_request_repository.dart';
import 'package:hr_portal/repositories/login_hours_repository.dart';
import 'package:hr_portal/services/attendance_calendar_merge_service.dart';
import 'package:hr_portal/services/attendance_import_service.dart';
import 'package:hr_portal/services/biometric_calendar_sync_service.dart';
import 'package:hr_portal/services/employee_access_sync_service.dart';
import 'package:hr_portal/services/employee_roster_import_service.dart';
import 'package:hr_portal/services/leave_calculation_service.dart';
import 'package:hr_portal/services/leave_request_service.dart';
import 'package:hr_portal/services/opening_balance_import_service.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepositoryImpl();
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl();
});

final loginHoursRepositoryProvider = Provider<LoginHoursRepository>((ref) {
  return LoginHoursRepositoryImpl();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl();
});

final holidayCalendarRepositoryProvider = Provider<HolidayCalendarRepository>((
  ref,
) {
  return HolidayCalendarRepositoryImpl();
});

final leaveRequestRepositoryProvider = Provider<LeaveRequestRepository>((ref) {
  return LeaveRequestRepositoryImpl();
});

final leaveRequestServiceProvider = Provider<LeaveRequestService>((ref) {
  return LeaveRequestService(
    leaveRequestRepository: ref.watch(leaveRequestRepositoryProvider),
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
    leaveCalculationService: ref.watch(leaveCalculationServiceProvider),
  );
});

final leaveCalculationServiceProvider = Provider<LeaveCalculationService>((
  ref,
) {
  return const LeaveCalculationService();
});

final attendanceCalendarMergeServiceProvider =
    Provider<AttendanceCalendarMergeService>((ref) {
      return const AttendanceCalendarMergeService();
    });

final attendanceImportServiceProvider = Provider<AttendanceImportService>((
  ref,
) {
  return AttendanceImportService(
    employeeRepository: ref.watch(employeeRepositoryProvider),
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
  );
});

final openingBalanceImportServiceProvider =
    Provider<OpeningBalanceImportService>((ref) {
      return OpeningBalanceImportService(ref.watch(employeeRepositoryProvider));
    });

final employeeRosterImportServiceProvider =
    Provider<EmployeeRosterImportService>((ref) {
      return EmployeeRosterImportService(ref.watch(employeeRepositoryProvider));
    });

final employeeAccessSyncServiceProvider = Provider<EmployeeAccessSyncService>((
  ref,
) {
  return EmployeeAccessSyncService(
    employeeRepository: ref.watch(employeeRepositoryProvider),
  );
});

final biometricCalendarSyncServiceProvider =
    Provider<BiometricCalendarSyncService>((ref) {
      return BiometricCalendarSyncService(
        employeeRepository: ref.watch(employeeRepositoryProvider),
        attendanceRepository: ref.watch(attendanceRepositoryProvider),
      );
    });

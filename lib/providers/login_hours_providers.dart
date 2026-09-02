import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/providers/admin_auth_providers.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/employee_providers.dart';
import 'package:hr_portal/providers/repository_providers.dart';
import 'package:hr_portal/services/login_hours_display_service.dart';
import 'package:hr_portal/services/login_hours_excel_exporter.dart';
import 'package:hr_portal/services/login_hours_range.dart';
import 'package:hr_portal/services/login_hours_status_resolver.dart';
import 'package:hr_portal/services/login_hours_sync_service.dart';

final loginHoursDisplayServiceProvider = Provider<LoginHoursDisplayService>((
  ref,
) {
  return const LoginHoursDisplayService();
});

final loginHoursSyncServiceProvider = Provider<LoginHoursSyncService>((ref) {
  return const LoginHoursSyncService();
});

final loginHoursStatusResolverProvider = Provider<LoginHoursStatusResolver>((
  ref,
) {
  return const LoginHoursStatusResolver();
});

final loginHoursExcelExporterProvider = Provider<LoginHoursExcelExporter>((
  ref,
) {
  return LoginHoursExcelExporter(
    displayService: ref.watch(loginHoursDisplayServiceProvider),
  );
});

final selectedLoginHoursDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final loginHoursPeriodProvider = StateProvider<LoginHoursPeriod>(
  (ref) => LoginHoursPeriod.day,
);

final loginHoursCustomStartProvider = StateProvider<DateTime?>((ref) => null);
final loginHoursCustomEndProvider = StateProvider<DateTime?>((ref) => null);

/// True when the signed-in HR admin (portal or Firebase) can view/edit all
/// employee login hours.
final canManageLoginHoursProvider = Provider<bool>((ref) {
  return ref.watch(adminAuthProvider) || ref.watch(isHrAdminAccountProvider);
});

final loginHoursRangeProvider = Provider<LoginHoursDateRange>((ref) {
  return const LoginHoursRange().resolve(
    period: ref.watch(loginHoursPeriodProvider),
    anchor: ref.watch(selectedLoginHoursDateProvider),
    customStart: ref.watch(loginHoursCustomStartProvider),
    customEnd: ref.watch(loginHoursCustomEndProvider),
  );
});

/// Signed-in employee name for the own-hours heading. Null for HR admin view.
final loginHoursViewerNameProvider = Provider<String?>((ref) {
  if (ref.watch(canManageLoginHoursProvider)) {
    return null;
  }
  final name = ref.watch(currentEmployeeProvider).valueOrNull?.name;
  if (name == null || name.trim().isEmpty) {
    return null;
  }
  return name;
});

final loginHoursForDateProvider =
    FutureProvider.autoDispose<List<LoginHoursRecord>>((ref) async {
      final range = ref.watch(loginHoursRangeProvider);
      final repository = ref.watch(loginHoursRepositoryProvider);
      if (ref.watch(canManageLoginHoursProvider)) {
        if (range.isSingleDay) {
          return repository.getRecordsForDate(range.start);
        }
        return repository.getRecordsForDateRange(
          start: range.start,
          end: range.end,
        );
      }

      final employee = await ref.watch(currentEmployeeProvider.future);
      if (employee == null) {
        return const [];
      }

      final rosterEntry = BiometricEmployeeRoster.findByEmployeeName(
        employee.name,
      );
      if (rosterEntry == null) {
        throw const DataException(
          'Your profile is not linked to biometric login hours. Contact HR.',
        );
      }

      return repository.getRecordsForEmployeeRange(
        employeeId: rosterEntry.normalizedId,
        start: range.start,
        end: range.end,
      );
    });

final loginHoursEditControllerProvider =
    StateNotifierProvider<LoginHoursEditController, AsyncValue<void>>((ref) {
      return LoginHoursEditController(ref);
    });

class LoginHoursEditController extends StateNotifier<AsyncValue<void>> {
  LoginHoursEditController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> saveManualEdit({
    required LoginHoursRecord record,
    required String firstIn,
    required String lastOut,
    required String status,
    required String remarks,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(authServiceProvider).ensureAdminSignedIn();

      final resolvedStatus = _ref
          .read(loginHoursStatusResolverProvider)
          .resolve(firstIn: firstIn, lastOut: lastOut, statusInput: status);

      await _ref
          .read(loginHoursRepositoryProvider)
          .updateManually(
            record: record,
            firstIn: firstIn,
            lastOut: lastOut,
            status: resolvedStatus,
            remarks: remarks,
          );

      await _syncEmployeeCalendar(
        record: record,
        status: resolvedStatus,
      );

      _ref.invalidate(loginHoursForDateProvider);
      _ref.invalidate(monthlyAttendanceProvider);
      _ref.invalidate(leaveBalanceProvider);
    });
  }

  Future<void> _syncEmployeeCalendar({
    required LoginHoursRecord record,
    required String status,
  }) async {
    final upper = status.trim().toUpperCase();
    if (upper == 'WEEKOFF') {
      return;
    }

    // Only sync statuses that biometric calendar sync also writes. SL/HL stay
    // login-hours-driven so a later time correction can clear them on the
    // employee calendar without being blocked by a stored leave status.
    const syncable = {
      AttendanceStatus.present,
      AttendanceStatus.latePunch,
      AttendanceStatus.absent,
      AttendanceStatus.wfh,
    };
    if (!syncable.contains(upper)) {
      return;
    }

    final employees = await _ref
        .read(employeeRepositoryProvider)
        .getAllEmployees();
    final employee = _findEmployee(record.employeeName, employees);
    if (employee == null || employee.email.trim().isEmpty) {
      return;
    }

    await _ref
        .read(attendanceRepositoryProvider)
        .importBiometricAttendanceRecords([
          AttendanceRecord(
            employeeName: employee.name,
            employeeEmail: employee.email.trim().toLowerCase(),
            date: record.date,
            status: upper,
          ),
        ]);
  }

  Employee? _findEmployee(String biometricName, List<Employee> employees) {
    final target = _normalize(_stripWfhLabel(biometricName));
    if (target.isEmpty) return null;

    final withEmail = employees.where(
      (employee) => employee.email.trim().isNotEmpty,
    );

    for (final employee in withEmail) {
      if (_normalize(_stripWfhLabel(employee.name)) == target) {
        return employee;
      }
    }

    final prefixMatches = withEmail
        .where(
          (employee) =>
              _normalize(_stripWfhLabel(employee.name)).startsWith('$target '),
        )
        .toList();
    if (prefixMatches.length == 1) {
      return prefixMatches.first;
    }
    return null;
  }

  String _stripWfhLabel(String name) {
    return name.replaceAll(RegExp(r'\s*\(WFH\)\s*', caseSensitive: false), ' ');
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String loginHoursErrorMessage(Object error) {
  if (error is AppException) {
    return error.message;
  }
  return error.toString();
}

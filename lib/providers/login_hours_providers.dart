import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/providers/admin_auth_providers.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/repository_providers.dart';
import 'package:hr_portal/services/login_hours_display_service.dart';
import 'package:hr_portal/services/login_hours_range.dart';
import 'package:hr_portal/services/login_hours_sync_service.dart';

final loginHoursDisplayServiceProvider = Provider<LoginHoursDisplayService>((
  ref,
) {
  return const LoginHoursDisplayService();
});

final loginHoursSyncServiceProvider = Provider<LoginHoursSyncService>((ref) {
  return const LoginHoursSyncService();
});

final selectedLoginHoursDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final loginHoursPeriodProvider = StateProvider<LoginHoursPeriod>(
  (ref) => LoginHoursPeriod.day,
);

final loginHoursCustomStartProvider = StateProvider<DateTime?>((ref) => null);
final loginHoursCustomEndProvider = StateProvider<DateTime?>((ref) => null);

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
  if (ref.watch(isHrAdminAccountProvider)) {
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
      if (ref.watch(isHrAdminAccountProvider)) {
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
      await _ref
          .read(loginHoursRepositoryProvider)
          .updateManually(
            record: record,
            firstIn: firstIn,
            lastOut: lastOut,
            status: status,
            remarks: remarks,
          );
      _ref.invalidate(loginHoursForDateProvider);
    });
  }
}

String loginHoursErrorMessage(Object error) {
  if (error is AppException) {
    return error.message;
  }
  return error.toString();
}

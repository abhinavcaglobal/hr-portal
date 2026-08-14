import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/repository_providers.dart';
import 'package:hr_portal/services/login_hours_display_service.dart';
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

final loginHoursForDateProvider =
    FutureProvider.autoDispose<List<LoginHoursRecord>>((ref) async {
      final date = ref.watch(selectedLoginHoursDateProvider);
      final repository = ref.watch(loginHoursRepositoryProvider);
      return repository.getRecordsForDate(date);
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

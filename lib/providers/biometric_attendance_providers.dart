import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/employee_providers.dart';
import 'package:hr_portal/providers/repository_providers.dart';
import 'package:hr_portal/services/biometric_attendance_service.dart';
import 'package:hr_portal/services/biometric_calendar_sync_service.dart';

final biometricAttendanceServiceProvider = Provider<BiometricAttendanceService>(
  (ref) {
    return const BiometricAttendanceService();
  },
);

final biometricProcessResultProvider = StateProvider<BiometricProcessResult?>(
  (ref) => null,
);

final biometricCalendarSyncResultProvider =
    StateProvider<BiometricCalendarSyncResult?>((ref) => null);

final biometricAttendanceControllerProvider =
    StateNotifierProvider<
      BiometricAttendanceController,
      AsyncValue<BiometricProcessResult?>
    >((ref) {
      return BiometricAttendanceController(ref);
    });

class BiometricAttendanceController
    extends StateNotifier<AsyncValue<BiometricProcessResult?>> {
  BiometricAttendanceController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<BiometricProcessResult> processFile({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(authServiceProvider).ensureAdminSignedIn();
      final result = _ref
          .read(biometricAttendanceServiceProvider)
          .processFile(bytes: fileBytes, fileName: fileName);
      await _ref
          .read(loginHoursRepositoryProvider)
          .importFromBiometricRecords(result.records);
      final calendarSync = await _ref
          .read(biometricCalendarSyncServiceProvider)
          .sync(result.records);
      _ref.read(biometricCalendarSyncResultProvider.notifier).state =
          calendarSync;
      _ref.read(biometricProcessResultProvider.notifier).state = result;
      _refreshDashboardData();
      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void _refreshDashboardData() {
    _ref.invalidate(leaveBalanceProvider);
    _ref.invalidate(monthlyAttendanceProvider);
  }
}

String biometricErrorMessage(Object error) {
  if (error is AppException) {
    return error.message;
  }
  return error.toString();
}

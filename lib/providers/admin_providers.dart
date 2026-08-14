import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/models/upload_history_record.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/employee_providers.dart';
import 'package:hr_portal/providers/repository_providers.dart';

final uploadHistoryProvider = StreamProvider<List<UploadHistoryRecord>>((ref) {
  return ref.watch(adminRepositoryProvider).watchUploadHistory();
});

final adminUploadControllerProvider =
    StateNotifierProvider<
      AdminUploadController,
      AsyncValue<AdminUploadResult?>
    >((ref) {
      return AdminUploadController(ref);
    });

class AdminUploadResult {
  const AdminUploadResult({required this.message, this.warnings = const []});

  final String message;
  final List<String> warnings;
}

class AdminUploadController
    extends StateNotifier<AsyncValue<AdminUploadResult?>> {
  AdminUploadController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> uploadFile({
    required String fileName,
    required UploadType uploadType,
    required Uint8List fileBytes,
    int? attendanceYear,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(authServiceProvider).ensureAdminSignedIn();

      if (uploadType == UploadType.attendance) {
        final year = attendanceYear ?? DateTime.now().year;
        final result = await _ref
            .read(attendanceImportServiceProvider)
            .importFromFile(bytes: fileBytes, fileName: fileName, year: year);

        await _ref
            .read(adminRepositoryProvider)
            .logImportHistory(
              fileName: fileName,
              uploadType: uploadType,
              uploadedBy: AppConstants.adminEmail,
              status: 'imported',
              details: result.summary,
            );

        _archiveInBackground(fileName, uploadType, fileBytes);
        _refreshDashboardData();

        return AdminUploadResult(
          message: result.summary,
          warnings: result.warnings,
        );
      }

      if (uploadType == UploadType.employeeRoster) {
        final result = await _ref
            .read(employeeRosterImportServiceProvider)
            .importFromFile(bytes: fileBytes, fileName: fileName);

        final syncResult = await _ref
            .read(employeeAccessSyncServiceProvider)
            .syncAll();

        await _ref
            .read(adminRepositoryProvider)
            .logImportHistory(
              fileName: fileName,
              uploadType: uploadType,
              uploadedBy: AppConstants.adminEmail,
              status: 'imported',
              details: '${result.summary} ${syncResult.summary}',
            );

        _archiveInBackground(fileName, uploadType, fileBytes);
        _refreshDashboardData();

        return AdminUploadResult(
          message: '${result.summary}\n${syncResult.summary}',
        );
      }

      final result = await _ref
          .read(openingBalanceImportServiceProvider)
          .importFromFile(bytes: fileBytes, fileName: fileName);

      await _ref
          .read(adminRepositoryProvider)
          .logImportHistory(
            fileName: fileName,
            uploadType: uploadType,
            uploadedBy: AppConstants.adminEmail,
            status: 'imported',
            details: result.summary,
          );

      _archiveInBackground(fileName, uploadType, fileBytes);
      _refreshDashboardData();

      return AdminUploadResult(message: result.summary);
    });
  }

  void _refreshDashboardData() {
    _ref.invalidate(currentEmployeeProvider);
    _ref.invalidate(employeeProvider);
    _ref.invalidate(leaveBalanceProvider);
    _ref.invalidate(monthlyAttendanceProvider);
  }

  void _archiveInBackground(
    String fileName,
    UploadType uploadType,
    Uint8List fileBytes,
  ) {
    _ref
        .read(adminRepositoryProvider)
        .archiveFileToStorage(
          fileName: fileName,
          uploadType: uploadType,
          uploadedBy: AppConstants.adminEmail,
          fileBytes: fileBytes,
        )
        .catchError((_) {});
  }

  Future<void> syncEmployeeAccess() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(authServiceProvider).ensureAdminSignedIn();
      final result = await _ref
          .read(employeeAccessSyncServiceProvider)
          .syncAll();
      _refreshDashboardData();
      return AdminUploadResult(message: result.summary);
    });
  }
}

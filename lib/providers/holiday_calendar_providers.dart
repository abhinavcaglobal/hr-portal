import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/models/holiday_calendar_document.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/repository_providers.dart';

final holidayCalendarProvider = StreamProvider<HolidayCalendarDocument?>((ref) {
  return ref.watch(holidayCalendarRepositoryProvider).watchCurrentCalendar();
});

final holidayCalendarUploadControllerProvider =
    StateNotifierProvider<HolidayCalendarUploadController, AsyncValue<String?>>(
      (ref) {
        return HolidayCalendarUploadController(ref);
      },
    );

class HolidayCalendarUploadController
    extends StateNotifier<AsyncValue<String?>> {
  HolidayCalendarUploadController(this._ref)
    : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> upload({
    required String fileName,
    required Uint8List fileBytes,
    required int year,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        throw const FormatException('Please select a PDF file.');
      }
      if (fileBytes.isEmpty) {
        throw const FormatException('The selected PDF file is empty.');
      }

      await _ref.read(authServiceProvider).ensureAdminSignedIn();
      await _ref
          .read(holidayCalendarRepositoryProvider)
          .uploadCalendar(
            fileName: fileName,
            fileBytes: fileBytes,
            year: year,
            uploadedBy: AppConstants.adminEmail,
          );
      return '$year holiday calendar uploaded successfully.';
    });
  }
}

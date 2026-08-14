import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/core/widgets/loading_overlay.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/admin/presentation/admin_nav.dart';
import 'package:hr_portal/features/admin/presentation/widgets/admin_shell.dart';
import 'package:hr_portal/features/admin/presentation/widgets/data_upload_section.dart';
import 'package:hr_portal/providers/admin_providers.dart';
import 'package:hr_portal/providers/holiday_calendar_providers.dart';

class AdminUploadPage extends ConsumerWidget {
  const AdminUploadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(adminUploadControllerProvider);
    final holidayUploadState = ref.watch(
      holidayCalendarUploadControllerProvider,
    );
    final isUploading = uploadState.isLoading || holidayUploadState.isLoading;

    ref.listen(adminUploadControllerProvider, (previous, next) {
      if (next.hasError) {
        final error = next.error!;
        final message = error is AppException
            ? error.message
            : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 8),
          ),
        );
      } else if (next.hasValue &&
          next.value != null &&
          previous?.isLoading == true) {
        final result = next.value!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            duration: const Duration(seconds: 6),
          ),
        );
        if (result.warnings.isNotEmpty && context.mounted) {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import notes'),
              content: SingleChildScrollView(
                child: Text(result.warnings.join('\n')),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    });

    ref.listen(holidayCalendarUploadControllerProvider, (previous, next) {
      if (next.hasError) {
        final error = next.error!;
        final message = error is AppException
            ? error.message
            : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else if (next.hasValue &&
          next.value != null &&
          previous?.isLoading == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.value!)));
      }
    });

    return AdminShell(
      current: AdminNavItem.dataUpload,
      body: Stack(
        children: [
          ResponsivePadding(
            child: SingleChildScrollView(
              child: DataUploadSection(isUploading: isUploading),
            ),
          ),
          if (isUploading)
            Container(
              color: Colors.black26,
              child: LoadingOverlay(
                message: holidayUploadState.isLoading
                    ? 'Uploading holiday calendar...'
                    : 'Importing data...',
              ),
            ),
        ],
      ),
    );
  }
}

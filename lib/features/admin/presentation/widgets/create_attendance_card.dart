import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/constants/upload_file_types.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/providers/biometric_attendance_providers.dart';

class CreateAttendanceCard extends ConsumerWidget {
  const CreateAttendanceCard({super.key, this.isDisabled = false});

  final bool isDisabled;

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: UploadFileTypes.allowedExtensions,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file data.')),
        );
      }
      return;
    }

    try {
      await ref
          .read(biometricAttendanceControllerProvider.notifier)
          .processFile(fileName: file.name, fileBytes: file.bytes!);
      if (context.mounted) {
        context.go(AppRoutes.adminBiometricResults);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(biometricErrorMessage(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref
        .watch(biometricAttendanceControllerProvider)
        .isLoading;
    final disabled = isDisabled || isProcessing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Attendance',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message:
                      'Upload a biometric export sheet. The system matches '
                      'employees by name and ID, then records first IN and '
                      'last OUT per weekday. Saturday and Sunday show '
                      'weekoff. If no record is found for an employee on a '
                      'weekday, it is marked L.',
                  triggerMode: TooltipTriggerMode.tap,
                  waitDuration: const Duration(milliseconds: 200),
                  showDuration: const Duration(seconds: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Create and manage employee attendance records',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: disabled ? null : () => _onPressed(context, ref),
                icon: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.edit_calendar_outlined),
                label: Text(
                  isProcessing ? 'Processing...' : 'Create Attendance',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

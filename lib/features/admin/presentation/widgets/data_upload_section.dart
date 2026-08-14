import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/upload_file_types.dart';
import 'package:hr_portal/models/upload_history_record.dart';
import 'package:hr_portal/providers/admin_providers.dart';
import 'package:hr_portal/providers/holiday_calendar_providers.dart';

class DataUploadSection extends ConsumerWidget {
  const DataUploadSection({super.key, required this.isUploading});

  final bool isUploading;

  Future<int?> _askHolidayYear(BuildContext context) {
    final controller = TextEditingController(text: '${DateTime.now().year}');

    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Holiday calendar year'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Year',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final year = int.tryParse(controller.text.trim());
              if (year == null || year < 2000 || year > 2100) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Enter a valid year.')),
                );
                return;
              }
              Navigator.of(dialogContext).pop(year);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadHolidayCalendar(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
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

    if (!context.mounted) return;
    final year = await _askHolidayYear(context);
    if (year == null) return;

    await ref
        .read(holidayCalendarUploadControllerProvider.notifier)
        .upload(fileName: file.name, fileBytes: file.bytes!, year: year);
  }

  Future<int?> _askAttendanceYear(BuildContext context) {
    final controller = TextEditingController(text: '${DateTime.now().year}');

    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Attendance year'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The month is read from your sheet (cell B1, e.g. June). '
              'Enter the calendar year for these dates.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final year = int.tryParse(controller.text.trim());
              if (year == null || year < 2000 || year > 2100) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Enter a valid year.')),
                );
                return;
              }
              Navigator.of(dialogContext).pop(year);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref,
    UploadType type,
  ) async {
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

    int? attendanceYear;
    if (type == UploadType.attendance) {
      if (!context.mounted) return;
      attendanceYear = await _askAttendanceYear(context);
      if (attendanceYear == null) return;
    }

    await ref
        .read(adminUploadControllerProvider.notifier)
        .uploadFile(
          fileName: file.name,
          uploadType: type,
          fileBytes: file.bytes!,
          attendanceYear: attendanceYear,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Data Upload',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message:
                      'Upload opening balance and attendance sheets for all '
                      'employees.\n\n'
                      'Opening balance: one row per employee (name, email, '
                      'openingBalance). Balance is through end of May; monthly '
                      'accrual starts in June.\n\n'
                      'Attendance sheet format (your HR layout):\n'
                      '• Row 1: S.no | Month (e.g. June) | 1 | 2 | 3 | ...\n'
                      '• Row 2: (blank) | EMPLOYEE NAME | Mon | Tue | ...\n'
                      '• Row 3+: serial | employee name | P/L/HL/SL per day\n'
                      '• Use P, L, HL, SL. Weekends "-" are ignored.',
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
              'Upload attendance, roster and opening balance files',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            _SyncEmployeeAccessButton(isUploading: isUploading),
            const SizedBox(height: 12),
            _UploadButton(
              icon: Icons.people_outline,
              title: 'Upload Employee Roster',
              subtitle: 'CSV or Excel — columns: name, email, openingBalance',
              onPressed: isUploading
                  ? null
                  : () =>
                        _pickAndUpload(context, ref, UploadType.employeeRoster),
            ),
            const SizedBox(height: 12),
            _UploadButton(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Upload Opening Balance File',
              subtitle:
                  'CSV or Excel — columns: name, openingBalance (email optional)',
              onPressed: isUploading
                  ? null
                  : () =>
                        _pickAndUpload(context, ref, UploadType.openingBalance),
            ),
            const SizedBox(height: 12),
            _UploadButton(
              icon: Icons.calendar_month_outlined,
              title: 'Upload Attendance File',
              subtitle: 'Wide matrix — employees in rows, days in columns',
              onPressed: isUploading
                  ? null
                  : () => _pickAndUpload(context, ref, UploadType.attendance),
            ),
            const SizedBox(height: 12),
            _UploadButton(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Upload Holiday Calendar',
              subtitle: 'PDF only — replaces the calendar employees can view',
              onPressed: isUploading
                  ? null
                  : () => _pickAndUploadHolidayCalendar(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncEmployeeAccessButton extends ConsumerWidget {
  const _SyncEmployeeAccessButton({required this.isUploading});

  final bool isUploading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: isUploading
          ? null
          : () => ref
                .read(adminUploadControllerProvider.notifier)
                .syncEmployeeAccess(),
      icon: const Icon(Icons.sync_lock_outlined),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
      ),
      label: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fix Employee Attendance Access',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Run once after enabling login, or when employees see permission errors',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.upload_file),
        ],
      ),
    );
  }
}

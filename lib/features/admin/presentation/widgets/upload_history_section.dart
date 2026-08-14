import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/widgets/error_view.dart';
import 'package:hr_portal/core/widgets/loading_overlay.dart';
import 'package:hr_portal/models/upload_history_record.dart';
import 'package:intl/intl.dart';

class UploadHistorySection extends StatelessWidget {
  const UploadHistorySection({super.key, required this.uploadHistory});

  final AsyncValue<List<UploadHistoryRecord>> uploadHistory;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload History',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'View all previously uploaded files and history',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            uploadHistory.when(
              loading: () => const AppLoadingIndicator(),
              error: (error, _) => ErrorView(message: error.toString()),
              data: (records) {
                if (records.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No uploads yet.')),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _UploadHistoryTile(record: record);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadHistoryTile extends StatelessWidget {
  const _UploadHistoryTile({required this.record});

  final UploadHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final type = UploadType.values.firstWhere(
      (t) => t.value == record.uploadType,
      orElse: () => UploadType.attendance,
    );
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(
          type == UploadType.openingBalance
              ? Icons.account_balance_wallet
              : Icons.calendar_month,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(record.fileName),
      subtitle: Text(
        '${type.label} · ${record.uploadedBy}\n'
        '${dateFormat.format(record.uploadedAt)}',
      ),
      isThreeLine: true,
      trailing: Chip(
        label: Text(record.status, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}

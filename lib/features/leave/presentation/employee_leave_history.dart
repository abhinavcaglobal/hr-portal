import 'package:flutter/material.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';
import 'package:hr_portal/models/leave_request.dart';
import 'package:hr_portal/services/leave_request_rules.dart';
import 'package:intl/intl.dart';

class EmployeeLeaveHistory extends StatelessWidget {
  const EmployeeLeaveHistory({super.key, required this.requests});

  final List<LeaveRequest> requests;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leave History',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              Text(
                'No leave requests yet. Tap a date on the calendar to apply.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              )
            else
              ...requests.map((request) => _HistoryItem(request: request)),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.request});

  final LeaveRequest request;

  static const _rules = LeaveRequestRules();

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM').format(request.leaveDate);
    final duration = _rules.durationShortLabel(request.leaveDuration);
    final adminNote = request.adminComment?.trim();
    final hasAdminNote = adminNote != null && adminNote.isNotEmpty;
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              date,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request.leaveType} | $duration | '
                  '${request.isUnpaid ? '0.00' : request.leaveDeduction.toStringAsFixed(2)} | '
                  '${LeaveRequestStatus.label(request.status)}'
                  '${request.isUnpaid ? ' — Unpaid Leave' : ''}',
                ),
                if (request.reason != null &&
                    request.reason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${request.reason!.trim()}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
                if (hasAdminNote) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Admin Note: $adminNote',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

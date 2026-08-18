import 'package:flutter/material.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';
import 'package:hr_portal/models/leave_request.dart';
import 'package:hr_portal/services/leave_request_rules.dart';
import 'package:intl/intl.dart';

enum LeaveRequestDetailAction { close, applyAgain }

class LeaveRequestDetailDialog extends StatelessWidget {
  const LeaveRequestDetailDialog({super.key, required this.request});

  final LeaveRequest request;

  static const _rules = LeaveRequestRules();

  static Future<LeaveRequestDetailAction?> show(
    BuildContext context,
    LeaveRequest request,
  ) {
    return showDialog<LeaveRequestDetailAction>(
      context: context,
      builder: (context) => LeaveRequestDetailDialog(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy').format(request.leaveDate);
    final duration = _rules.durationShortLabel(request.leaveDuration);
    final details = _rules.halfOrTimeDetails(
      duration: request.leaveDuration,
      halfDayType: request.halfDayType,
      fromTime: request.fromTime,
      toTime: request.toTime,
    );
    final adminNote = request.adminComment?.trim();
    final hasAdminNote = adminNote != null && adminNote.isNotEmpty;
    final canApplyAgain = request.status == LeaveRequestStatus.declined;

    return AlertDialog(
      title: const Text('Leave Request'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Date', value: date),
            _DetailRow(label: 'Leave Type', value: request.leaveType),
            _DetailRow(label: 'Duration', value: duration),
            _DetailRow(
              label: 'Deduction',
              value: request.isUnpaid
                  ? '0.00 (Unpaid Leave)'
                  : request.leaveDeduction.toStringAsFixed(2),
            ),
            if (details != '-') _DetailRow(label: 'Details', value: details),
            _DetailRow(
              label: 'Status',
              value: LeaveRequestStatus.label(request.status),
            ),
            if (request.reason != null && request.reason!.trim().isNotEmpty)
              _DetailRow(label: 'Your Reason', value: request.reason!.trim()),
            if (request.isUnpaid)
              const _DetailRow(
                label: 'Note',
                value: UnpaidLeave.employeeNote,
              ),
            if (hasAdminNote)
              _DetailRow(label: 'Admin Note', value: adminNote),
            if (!hasAdminNote &&
                (request.status == LeaveRequestStatus.approved ||
                    request.status == LeaveRequestStatus.declined))
              Text(
                'No admin note was added for this decision.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(LeaveRequestDetailAction.close),
          child: const Text('Close'),
        ),
        if (canApplyAgain)
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(LeaveRequestDetailAction.applyAgain),
            child: const Text('Apply Again'),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

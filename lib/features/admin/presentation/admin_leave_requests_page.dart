import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/core/theme/app_theme.dart';
import 'package:hr_portal/core/widgets/error_view.dart';
import 'package:hr_portal/core/widgets/loading_overlay.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/admin/presentation/admin_nav.dart';
import 'package:hr_portal/features/admin/presentation/widgets/admin_shell.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/models/leave_request.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/employee_email_providers.dart';
import 'package:hr_portal/providers/leave_request_providers.dart';
import 'package:hr_portal/providers/repository_providers.dart';
import 'package:hr_portal/services/leave_request_rules.dart';
import 'package:intl/intl.dart';

class AdminLeaveRequestsPage extends ConsumerStatefulWidget {
  const AdminLeaveRequestsPage({super.key});

  @override
  ConsumerState<AdminLeaveRequestsPage> createState() =>
      _AdminLeaveRequestsPageState();
}

class _AdminLeaveRequestsPageState
    extends ConsumerState<AdminLeaveRequestsPage> {
  static const _rules = LeaveRequestRules();

  String _statusFilter = LeaveRequestStatus.pending;
  String? _employeeFilter;
  String? _leaveTypeFilter;
  DateTime? _fromDate;
  DateTime? _toDate;

  List<LeaveRequest> _applyFilters(List<LeaveRequest> requests) {
    return requests.where((request) {
      if (_statusFilter != 'ALL' && request.status != _statusFilter) {
        return false;
      }
      if (_employeeFilter != null && request.employeeId != _employeeFilter) {
        return false;
      }
      if (_leaveTypeFilter != null && request.leaveType != _leaveTypeFilter) {
        return false;
      }
      final date = DateTime(
        request.leaveDate.year,
        request.leaveDate.month,
        request.leaveDate.day,
      );
      if (_fromDate != null && date.isBefore(_fromDate!)) return false;
      if (_toDate != null && date.isAfter(_toDate!)) return false;
      return true;
    }).toList();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (range == null) return;
    setState(() {
      _fromDate = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      _toDate = DateTime(range.end.year, range.end.month, range.end.day);
    });
  }

  Future<void> _approve(LeaveRequest request) async {
    Employee? employee;
    var asUnpaid = false;
    var balance = 0.0;
    try {
      employee =
          await ref
              .read(employeeRepositoryProvider)
              .getEmployeeByEmail(request.employeeId) ??
          Employee(
            email: request.employeeId,
            name: request.employeeName,
            openingBalance: 0,
          );
      balance = await ref
          .read(leaveRequestServiceProvider)
          .currentBalanceFor(employee);
      asUnpaid = const LeaveRequestRules().isUnpaidLeave(
        balance,
        request.leaveDeduction,
      );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    final commentController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve leave request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to approve this leave request?'),
            if (asUnpaid) ...[
              const SizedBox(height: 12),
              Text(
                'Pending leave balance is ${balance.toStringAsFixed(2)}. '
                'This will be recorded as Unpaid Leave. Paid leave will not be deducted, '
                'and the employee will see a note: Unpaid Leave.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Admin comment (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(asUnpaid ? 'Approve as Unpaid Leave' : 'Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      commentController.dispose();
      return;
    }

    try {
      final adminId =
          ref.read(authStateProvider).valueOrNull?.email ??
          AppConstants.adminEmail;
      final result = await ref
          .read(leaveRequestServiceProvider)
          .approve(
            request: request,
            adminId: adminId,
            employee: employee,
            adminComment: commentController.text,
            asUnpaid: asUnpaid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyApproved
                ? 'This request was already approved. Leave was not deducted again.'
                : asUnpaid
                ? 'Leave request approved as Unpaid Leave. Paid balance was not deducted.'
                : 'Leave request approved. Balance deducted '
                      '${request.leaveDeduction.toStringAsFixed(2)}.',
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      commentController.dispose();
    }
  }

  Future<void> _decline(LeaveRequest request) async {
    final commentController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline leave request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to decline this leave request?'),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Decline reason / comment (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      commentController.dispose();
      return;
    }

    try {
      final adminId =
          ref.read(authStateProvider).valueOrNull?.email ??
          AppConstants.adminEmail;
      await ref
          .read(leaveRequestServiceProvider)
          .decline(
            request: request,
            adminId: adminId,
            adminComment: commentController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request declined. Balance was not deducted.'),
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      commentController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(adminLeaveRequestsProvider);
    final employeesAsync = ref.watch(allEmployeesProvider);

    return AdminShell(
      current: AdminNavItem.leaveRequests,
      body: ResponsivePadding(
        child: requestsAsync.when(
          loading: () =>
              const LoadingOverlay(message: 'Loading leave requests...'),
          error: (error, _) => ErrorView(
            message: error is AppException
                ? error.message
                : 'Failed to load leave requests.',
            onRetry: () => ref.invalidate(adminLeaveRequestsProvider),
          ),
          data: (requests) {
            final filtered = _applyFilters(requests);
            return ListView(
              children: [
                Text(
                  'Leave Requests',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review pending requests first. History is kept for approved and declined requests.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _FiltersBar(
                  statusFilter: _statusFilter,
                  employeeFilter: _employeeFilter,
                  leaveTypeFilter: _leaveTypeFilter,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  employees: employeesAsync.valueOrNull ?? const [],
                  onStatusChanged: (value) =>
                      setState(() => _statusFilter = value),
                  onEmployeeChanged: (value) =>
                      setState(() => _employeeFilter = value),
                  onLeaveTypeChanged: (value) =>
                      setState(() => _leaveTypeFilter = value),
                  onPickRange: _pickRange,
                  onClearDates: () => setState(() {
                    _fromDate = null;
                    _toDate = null;
                  }),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No leave requests match the current filters.',
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (request) => _RequestCard(
                      request: request,
                      details: _rules.halfOrTimeDetails(
                        duration: request.leaveDuration,
                        halfDayType: request.halfDayType,
                        fromTime: request.fromTime,
                        toTime: request.toTime,
                      ),
                      onApprove: request.status == LeaveRequestStatus.pending
                          ? () => _approve(request)
                          : null,
                      onDecline: request.status == LeaveRequestStatus.pending
                          ? () => _decline(request)
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.statusFilter,
    required this.employeeFilter,
    required this.leaveTypeFilter,
    required this.fromDate,
    required this.toDate,
    required this.employees,
    required this.onStatusChanged,
    required this.onEmployeeChanged,
    required this.onLeaveTypeChanged,
    required this.onPickRange,
    required this.onClearDates,
  });

  final String statusFilter;
  final String? employeeFilter;
  final String? leaveTypeFilter;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<Employee> employees;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String?> onEmployeeChanged;
  final ValueChanged<String?> onLeaveTypeChanged;
  final VoidCallback onPickRange;
  final VoidCallback onClearDates;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: statusFilter,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All')),
              DropdownMenuItem(
                value: LeaveRequestStatus.pending,
                child: Text('Pending'),
              ),
              DropdownMenuItem(
                value: LeaveRequestStatus.approved,
                child: Text('Approved'),
              ),
              DropdownMenuItem(
                value: LeaveRequestStatus.declined,
                child: Text('Declined'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onStatusChanged(value);
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            initialValue: employeeFilter,
            decoration: const InputDecoration(labelText: 'Employee'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All employees'),
              ),
              ...employees.map(
                (employee) => DropdownMenuItem<String?>(
                  value: employee.email.trim().toLowerCase(),
                  child: Text(employee.name),
                ),
              ),
            ],
            onChanged: onEmployeeChanged,
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            initialValue: leaveTypeFilter,
            decoration: const InputDecoration(labelText: 'Leave Type'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All types'),
              ),
              ...LeaveCategory.all.map(
                (type) =>
                    DropdownMenuItem<String?>(value: type, child: Text(type)),
              ),
            ],
            onChanged: onLeaveTypeChanged,
          ),
        ),
        OutlinedButton.icon(
          onPressed: onPickRange,
          icon: const Icon(Icons.date_range),
          label: Text(
            fromDate == null || toDate == null
                ? 'Date range'
                : '${DateFormat('d MMM').format(fromDate!)} – ${DateFormat('d MMM').format(toDate!)}',
          ),
        ),
        if (fromDate != null)
          TextButton(onPressed: onClearDates, child: const Text('Clear dates')),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.details,
    required this.onApprove,
    required this.onDecline,
  });

  final LeaveRequest request;
  final String details;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy').format(request.leaveDate);
    final requestedAt = DateFormat(
      'd MMM yyyy, HH:mm',
    ).format(request.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.employeeName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            if (request.isUnpaid) ...[
              const SizedBox(height: 8),
              const Text(
                'Unpaid Leave — paid leave was not deducted.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _Meta(label: 'Date', value: date),
                _Meta(label: 'Leave Type', value: request.leaveType),
                _Meta(
                  label: 'Duration',
                  value:
                      LeaveDuration.shortLabels[request.leaveDuration] ??
                      request.leaveDuration,
                ),
                _Meta(
                  label: 'Leave Deduction',
                  value: request.leaveDeduction.toStringAsFixed(2),
                ),
                _Meta(label: 'Half/Time Details', value: details),
                _Meta(
                  label: 'Reason',
                  value: (request.reason == null || request.reason!.isEmpty)
                      ? '-'
                      : request.reason!,
                ),
                _Meta(label: 'Requested At', value: requestedAt),
              ],
            ),
            if (onApprove != null || onDecline != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onDecline,
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
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
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      LeaveRequestStatus.pending => const Color(0xFFF9A825),
      LeaveRequestStatus.approved => AppTheme.successColor,
      LeaveRequestStatus.declined => AppTheme.errorColor,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        LeaveRequestStatus.label(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/core/widgets/app_logo.dart';
import 'package:hr_portal/core/widgets/error_view.dart';
import 'package:hr_portal/core/widgets/loading_overlay.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/attendance/presentation/attendance_calendar.dart';
import 'package:hr_portal/features/leave/presentation/apply_leave_dialog.dart';
import 'package:hr_portal/features/leave/presentation/employee_leave_history.dart';
import 'package:hr_portal/features/leave/presentation/leave_request_detail_dialog.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/models/leave_request.dart';
import 'package:hr_portal/providers/admin_auth_providers.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/employee_providers.dart';
import 'package:hr_portal/providers/leave_request_providers.dart';

class EmployeeDashboardPage extends ConsumerWidget {
  const EmployeeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(currentEmployeeProvider);
    final leaveBalanceAsync = ref.watch(leaveBalanceProvider);
    final isHrAdmin = ref.watch(isHrAdminAccountProvider);
    final isAdminSession = isHrAdmin ? ref.watch(adminAuthProvider) : false;
    final selectedMonth = ref.watch(selectedMonthProvider);
    final attendanceAsync = ref.watch(
      monthlyAttendanceProvider(
        AttendanceMonthParams(
          year: selectedMonth.year,
          month: selectedMonth.month,
        ),
      ),
    );
    final leaveRequestsAsync = ref.watch(employeeLeaveRequestsProvider);

    return employeeAsync.when(
      loading: () => const Scaffold(
        body: AppLoadingIndicator(message: 'Loading your profile...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const AppBarTitle()),
        body: ErrorView(message: error.toString()),
      ),
      data: (employee) {
        if (employee == null) {
          return Scaffold(
            appBar: AppBar(title: const AppBarTitle()),
            body: const ErrorView(
              message:
                  'Your email is not registered. Contact HR to be added to the roster.',
            ),
          );
        }

        if (employee.email.trim().isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const AppBarTitle()),
            body: const ErrorView(
              message:
                  'Your employee profile has no email. Ask HR to upload the employee roster with your work email.',
            ),
          );
        }

        final userName = employee.name;
        final emailLabel = employee.email.isNotEmpty
            ? employee.email
            : 'Employee profile';

        return Scaffold(
          appBar: AppBar(
            title: AppBarTitle(subtitle: emailLabel),
            leading: IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Home',
              onPressed: () => context.go(AppRoutes.home),
            ),
            actions: [
              if (isHrAdmin)
                TextButton.icon(
                  onPressed: () {
                    if (isAdminSession) {
                      context.go(AppRoutes.adminDashboard);
                    } else {
                      context.go(AppRoutes.adminLogin);
                    }
                  },
                  icon: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                  ),
                  label: Text(
                    isAdminSession ? 'Admin Portal' : 'Admin',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              TextButton.icon(
                onPressed: () async {
                  ref.read(adminAuthProvider.notifier).logoutAdminOnly();
                  await ref.read(authServiceProvider).signOut();
                  ref.invalidate(currentEmployeeProvider);
                  if (context.mounted) {
                    context.go(AppRoutes.home);
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: ResponsivePadding(
            child: SingleChildScrollView(
              child: ResponsiveLayout(
                mobile: _DashboardColumn(
                  employee: employee,
                  userName: userName,
                  userEmail: emailLabel,
                  leaveBalanceAsync: leaveBalanceAsync,
                  selectedMonth: selectedMonth,
                  attendanceAsync: attendanceAsync,
                  leaveRequestsAsync: leaveRequestsAsync,
                  onMonthChanged: (date) =>
                      ref.read(selectedMonthProvider.notifier).state = date,
                ),
                tablet: _DashboardRow(
                  employee: employee,
                  userName: userName,
                  userEmail: emailLabel,
                  leaveBalanceAsync: leaveBalanceAsync,
                  selectedMonth: selectedMonth,
                  attendanceAsync: attendanceAsync,
                  leaveRequestsAsync: leaveRequestsAsync,
                  onMonthChanged: (date) =>
                      ref.read(selectedMonthProvider.notifier).state = date,
                ),
                desktop: _DashboardRow(
                  employee: employee,
                  userName: userName,
                  userEmail: emailLabel,
                  leaveBalanceAsync: leaveBalanceAsync,
                  selectedMonth: selectedMonth,
                  attendanceAsync: attendanceAsync,
                  leaveRequestsAsync: leaveRequestsAsync,
                  onMonthChanged: (date) =>
                      ref.read(selectedMonthProvider.notifier).state = date,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardColumn extends StatelessWidget {
  const _DashboardColumn({
    required this.employee,
    required this.userName,
    required this.userEmail,
    required this.leaveBalanceAsync,
    required this.selectedMonth,
    required this.attendanceAsync,
    required this.leaveRequestsAsync,
    required this.onMonthChanged,
  });

  final Employee employee;
  final String userName;
  final String userEmail;
  final AsyncValue<double> leaveBalanceAsync;
  final DateTime selectedMonth;
  final AsyncValue<List<AttendanceRecord>> attendanceAsync;
  final AsyncValue<List<LeaveRequest>> leaveRequestsAsync;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EmployeeInfoCard(name: userName, email: userEmail),
        const SizedBox(height: 16),
        _LeaveBalanceCard(leaveBalanceAsync: leaveBalanceAsync),
        const SizedBox(height: 16),
        _LoginHoursCard(),
        const SizedBox(height: 16),
        const _HolidayCalendarCard(),
        const SizedBox(height: 16),
        _AttendanceSection(
          employee: employee,
          selectedMonth: selectedMonth,
          attendanceAsync: attendanceAsync,
          leaveRequestsAsync: leaveRequestsAsync,
          onMonthChanged: onMonthChanged,
        ),
        const SizedBox(height: 16),
        EmployeeLeaveHistory(
          requests: leaveRequestsAsync.valueOrNull ?? const [],
        ),
      ],
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({
    required this.employee,
    required this.userName,
    required this.userEmail,
    required this.leaveBalanceAsync,
    required this.selectedMonth,
    required this.attendanceAsync,
    required this.leaveRequestsAsync,
    required this.onMonthChanged,
  });

  final Employee employee;
  final String userName;
  final String userEmail;
  final AsyncValue<double> leaveBalanceAsync;
  final DateTime selectedMonth;
  final AsyncValue<List<AttendanceRecord>> attendanceAsync;
  final AsyncValue<List<LeaveRequest>> leaveRequestsAsync;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _EmployeeInfoCard(name: userName, email: userEmail),
                  const SizedBox(height: 16),
                  _LeaveBalanceCard(leaveBalanceAsync: leaveBalanceAsync),
                  const SizedBox(height: 16),
                  _LoginHoursCard(),
                  const SizedBox(height: 16),
                  const _HolidayCalendarCard(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _AttendanceSection(
                    employee: employee,
                    selectedMonth: selectedMonth,
                    attendanceAsync: attendanceAsync,
                    leaveRequestsAsync: leaveRequestsAsync,
                    onMonthChanged: onMonthChanged,
                  ),
                  const SizedBox(height: 16),
                  EmployeeLeaveHistory(
                    requests: leaveRequestsAsync.valueOrNull ?? const [],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmployeeInfoCard extends StatelessWidget {
  const _EmployeeInfoCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHoursCard extends StatelessWidget {
  const _LoginHoursCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go(AppRoutes.loginHours),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login Hours',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View employee login and logout timings',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HolidayCalendarCard extends StatelessWidget {
  const _HolidayCalendarCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go(AppRoutes.holidayCalendar),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Holiday Calendar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View the company holiday list',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  const _LeaveBalanceCard({required this.leaveBalanceAsync});

  final AsyncValue<double> leaveBalanceAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: leaveBalanceAsync.when(
          loading: () => const AppLoadingIndicator(
            message: 'Calculating leave balance...',
          ),
          error: (error, _) => ErrorView(message: error.toString()),
          data: (balance) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pending Leave Balance',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    balance.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'days',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Balance through May plus monthly carry-forward from June.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceSection extends ConsumerWidget {
  const _AttendanceSection({
    required this.employee,
    required this.selectedMonth,
    required this.attendanceAsync,
    required this.leaveRequestsAsync,
    required this.onMonthChanged,
  });

  final Employee employee;
  final DateTime selectedMonth;
  final AsyncValue<List<AttendanceRecord>> attendanceAsync;
  final AsyncValue<List<LeaveRequest>> leaveRequestsAsync;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Attendance Calendar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh attendance',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.invalidate(monthlyAttendanceProvider);
                    ref.invalidate(leaveBalanceProvider);
                    ref.invalidate(employeeLeaveRequestsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            attendanceAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (error, _) => ErrorView(message: error.toString()),
              data: (records) {
                final requests = leaveRequestsAsync.valueOrNull ?? const [];
                final overlays = requests
                    .where(
                      (request) =>
                          request.leaveDate.year == selectedMonth.year &&
                          request.leaveDate.month == selectedMonth.month,
                    )
                    .map(
                      (request) => CalendarLeaveOverlay(
                        day: request.leaveDate.day,
                        status: request.status,
                        duration: request.leaveDuration,
                        halfDayType: request.halfDayType,
                        fromTime: request.fromTime,
                        toTime: request.toTime,
                        isUnpaid: request.isUnpaid,
                        adminComment: request.adminComment,
                      ),
                    )
                    .toList();

                return AttendanceCalendar(
                  selectedMonth: selectedMonth,
                  records: records,
                  leaveOverlays: overlays,
                  onMonthChanged: onMonthChanged,
                  onDaySelected: (date) async {
                    final dayRequest = _requestForDate(requests, date);
                    if (dayRequest != null) {
                      final action = await LeaveRequestDetailDialog.show(
                        context,
                        dayRequest,
                      );
                      if (action != LeaveRequestDetailAction.applyAgain ||
                          !context.mounted) {
                        return;
                      }
                    }

                    final applied = await ApplyLeaveDialog.show(
                      context,
                      employee: employee,
                      leaveDate: date,
                    );
                    if (applied == true && context.mounted) {
                      ref.invalidate(employeeLeaveRequestsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Leave request submitted. It is pending HR approval and has not been deducted from your balance.',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const _StatusLegend(),
          ],
        ),
      ),
    );
  }

  LeaveRequest? _requestForDate(List<LeaveRequest> requests, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    for (final request in requests) {
      final requestDay = DateTime(
        request.leaveDate.year,
        request.leaveDate.month,
        request.leaveDate.day,
      );
      if (requestDay == day) {
        return request;
      }
    }
    return null;
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        ...AttendanceStatus.labels.entries.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendChip(
                color: AttendanceCalendar.statusColor(entry.key),
                label: entry.key,
              ),
              const SizedBox(width: 6),
              Text('${entry.key} – ${entry.value}'),
            ],
          );
        }),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendChip(
              color: AttendanceCalendar.overlayColor(LeaveRequestStatus.pending),
              label: 'Req',
            ),
            const SizedBox(width: 6),
            const Text('Requested Leave'),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendChip(
              color: AttendanceCalendar.overlayColor(
                LeaveRequestStatus.approved,
              ),
              label: 'OK',
              darkText: true,
            ),
            const SizedBox(width: 6),
            const Text('Approved Leave'),
          ],
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    this.darkText = false,
  });

  final Color color;
  final String label;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: darkText ? const Color(0xFF3E2723) : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/core/theme/app_theme.dart';
import 'package:hr_portal/core/utils/mailto_launcher.dart';
import 'package:hr_portal/core/widgets/error_view.dart';
import 'package:hr_portal/core/widgets/loading_overlay.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/admin/presentation/admin_nav.dart';
import 'package:hr_portal/features/admin/presentation/widgets/admin_shell.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/providers/employee_email_providers.dart';

class EmployeeEmailsPage extends ConsumerStatefulWidget {
  const EmployeeEmailsPage({super.key});

  @override
  ConsumerState<EmployeeEmailsPage> createState() => _EmployeeEmailsPageState();
}

class _EmployeeEmailsPageState extends ConsumerState<EmployeeEmailsPage> {
  static const _pageSize = 8;

  String _search = '';
  int _page = 0;

  Future<void> _openMailto(String email) async {
    final opened = await launchEmployeeMailto(email);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open Outlook. Set Outlook as your default mail app and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _openEmail(Employee employee) async {
    await _openMailto(employee.email);
  }

  Future<void> _openIndiaTeamEmail() async {
    await _openMailto(AppConstants.indiaTeamEmail);
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allEmployeesProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return AdminShell(
      current: AdminNavItem.employeeEmails,
      body: ResponsivePadding(
        child: employeesAsync.when(
          loading: () => const LoadingOverlay(message: 'Loading employees...'),
          error: (error, _) => ErrorView(
            message: error is AppException
                ? error.message
                : 'Failed to load employees.',
            onRetry: () => ref.invalidate(allEmployeesProvider),
          ),
          data: (employees) {
            final query = _search.toLowerCase();
            final filtered = employees.where((employee) {
              if (query.isEmpty) {
                return true;
              }
              return employee.name.toLowerCase().contains(query) ||
                  employee.email.toLowerCase().contains(query);
            }).toList();

            final pageCount = filtered.isEmpty
                ? 1
                : (filtered.length / _pageSize).ceil();
            final page = _page.clamp(0, pageCount - 1);
            final start = filtered.isEmpty ? 0 : page * _pageSize;
            final end = filtered.isEmpty
                ? 0
                : (start + _pageSize > filtered.length
                      ? filtered.length
                      : start + _pageSize);
            final pageItems = filtered.isEmpty
                ? const <Employee>[]
                : filtered.sublist(start, end);

            final table = _EmployeeTableCard(
              expand: isDesktop,
              totalCount: employees.length,
              filteredCount: filtered.length,
              page: page,
              pageCount: pageCount,
              start: filtered.isEmpty ? 0 : start + 1,
              end: end,
              employees: pageItems,
              onSearch: (value) => setState(() {
                _search = value.trim();
                _page = 0;
              }),
              onRefresh: () => ref.invalidate(allEmployeesProvider),
              onPage: (next) => setState(() => _page = next),
              onEmail: _openEmail,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Employee Emails',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => context.go(AppRoutes.adminDashboard),
                      child: Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                    Text(
                      '  >  Employee Emails',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an employee to open Outlook and send an email.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _openIndiaTeamEmail,
                    icon: const Icon(Icons.groups_outlined, size: 18),
                    label: const Text('Email India Team'),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: table),
                            const SizedBox(width: 20),
                            const SizedBox(
                              width: 280,
                              child: HowItWorksCard(),
                            ),
                          ],
                        )
                      : ListView(
                          children: [
                            table,
                            const SizedBox(height: 20),
                            const HowItWorksCard(),
                          ],
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

class _EmployeeTableCard extends StatelessWidget {
  const _EmployeeTableCard({
    required this.expand,
    required this.totalCount,
    required this.filteredCount,
    required this.page,
    required this.pageCount,
    required this.start,
    required this.end,
    required this.employees,
    required this.onSearch,
    required this.onRefresh,
    required this.onPage,
    required this.onEmail,
  });

  final bool expand;
  final int totalCount;
  final int filteredCount;
  final int page;
  final int pageCount;
  final int start;
  final int end;
  final List<Employee> employees;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;
  final ValueChanged<int> onPage;
  final Future<void> Function(Employee) onEmail;

  @override
  Widget build(BuildContext context) {
    final tableBody = employees.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                totalCount == 0
                    ? 'No employees found.'
                    : 'No matching employees.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        : SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  AppTheme.primaryColor.withValues(alpha: 0.06),
                ),
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Employee Name')),
                  DataColumn(label: Text('Email Address')),
                  DataColumn(label: Text('Department')),
                  DataColumn(label: Text('Action')),
                ],
                rows: [
                  for (var i = 0; i < employees.length; i++)
                    DataRow(
                      cells: [
                        DataCell(Text('${start + i}')),
                        DataCell(Text(employees[i].name)),
                        DataCell(
                          Text(
                            isValidEmployeeEmail(employees[i].email)
                                ? employees[i].email.trim()
                                : '—',
                          ),
                        ),
                        const DataCell(Text('—')),
                        DataCell(
                          EmployeeEmailButton(
                            employee: employees[i],
                            onPressed: () => onEmail(employees[i]),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'All Employees',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Select an employee to open Outlook and send an email.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 220,
                    maxWidth: 520,
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search employee by name or email...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: onSearch,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (expand)
              Expanded(child: tableBody)
            else
              tableBody,
            const SizedBox(height: 12),
            _PaginationBar(
              start: filteredCount == 0 ? 0 : start,
              end: end,
              total: filteredCount,
              page: page,
              pageCount: pageCount,
              onPage: onPage,
            ),
          ],
        ),
      ),
    );

    if (expand) {
      return SizedBox.expand(child: card);
    }
    return card;
  }
}

class EmployeeEmailButton extends StatelessWidget {
  const EmployeeEmailButton({
    super.key,
    required this.employee,
    required this.onPressed,
  });

  final Employee employee;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasEmail = isValidEmployeeEmail(employee.email);
    if (!hasEmail) {
      return Text(
        'Email Not Available',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.email_outlined, size: 16),
      label: const Text('Email'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class HowItWorksCard extends StatelessWidget {
  const HowItWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How it works',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('1. Click the Email button next to an employee.'),
            const SizedBox(height: 8),
            const Text(
              '2. Outlook will open with the employee\'s email in the To field.',
            ),
            const SizedBox(height: 8),
            const Text('3. Compose your email and send it from Outlook.'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This portal does not send emails. It only opens Outlook to help you compose an email.',
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.start,
    required this.end,
    required this.total,
    required this.page,
    required this.pageCount,
    required this.onPage,
  });

  final int start;
  final int end;
  final int total;
  final int page;
  final int pageCount;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final pages = _visiblePages(page, pageCount);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text('Showing $start to $end of $total employees'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous',
              onPressed: page > 0 ? () => onPage(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            for (final item in pages)
              item == null
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('...'),
                    )
                  : TextButton(
                      onPressed: () => onPage(item),
                      style: TextButton.styleFrom(
                        backgroundColor: item == page
                            ? AppTheme.primaryColor
                            : null,
                        foregroundColor: item == page
                            ? Colors.white
                            : AppTheme.primaryColor,
                        minimumSize: const Size(36, 36),
                      ),
                      child: Text('${item + 1}'),
                    ),
            IconButton(
              tooltip: 'Next',
              onPressed: page < pageCount - 1 ? () => onPage(page + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  List<int?> _visiblePages(int current, int count) {
    if (count <= 7) {
      return [for (var i = 0; i < count; i++) i];
    }
    if (current <= 3) {
      return [0, 1, 2, 3, 4, null, count - 1];
    }
    if (current >= count - 4) {
      return [0, null, count - 5, count - 4, count - 3, count - 2, count - 1];
    }
    return [0, null, current - 1, current, current + 1, null, count - 1];
  }
}

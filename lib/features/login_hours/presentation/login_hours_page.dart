import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/core/widgets/app_logo.dart';
import 'package:hr_portal/core/widgets/error_view.dart';
import 'package:hr_portal/core/widgets/loading_overlay.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/providers/admin_auth_providers.dart';
import 'package:hr_portal/providers/login_hours_providers.dart';
import 'package:hr_portal/services/login_hours_display_service.dart';
import 'package:intl/intl.dart';

class LoginHoursPage extends ConsumerWidget {
  const LoginHoursPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedLoginHoursDateProvider);
    final recordsAsync = ref.watch(loginHoursForDateProvider);
    final displayService = ref.watch(loginHoursDisplayServiceProvider);
    final canEdit = ref.watch(isHrAdminAccountProvider);
    final isSaving = ref.watch(loginHoursEditControllerProvider).isLoading;
    final dateFormat = DateFormat('dd MMM yyyy');

    ref.listen(loginHoursEditControllerProvider, (previous, next) {
      if (next.hasValue && !next.isLoading && previous?.isLoading == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login hours updated.')));
      }
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginHoursErrorMessage(next.error!)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(subtitle: 'Login Hours'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ResponsivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dateFormat.format(selectedDate),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(context, ref, selectedDate),
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: const Text('Change Date'),
                    ),
                  ],
                ),
              ),
            ),
            if (canEdit) ...[
              const SizedBox(height: 8),
              Text(
                'HR edit mode — tap a row to update In, Out, Status, or Remarks.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            recordsAsync.maybeWhen(
              data: (records) {
                if (records.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${records.length} employees',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use mouse wheel or drag scrollbar to see all rows',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  recordsAsync.when(
                    loading: () => const AppLoadingIndicator(
                      message: 'Loading login hours...',
                    ),
                    error: (error, _) => ErrorView(message: error.toString()),
                    data: (records) => _LoginHoursTable(
                      records: records,
                      selectedDate: selectedDate,
                      displayService: displayService,
                      canEdit: canEdit,
                    ),
                  ),
                  if (isSaving)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x33FFFFFF),
                        child: Center(child: CircularProgressIndicator()),
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

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime currentDate,
  ) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: today,
    );

    if (picked != null) {
      ref.read(selectedLoginHoursDateProvider.notifier).state = picked;
    }
  }
}

class _LoginHoursTable extends ConsumerWidget {
  const _LoginHoursTable({
    required this.records,
    required this.selectedDate,
    required this.displayService,
    required this.canEdit,
  });

  final List<LoginHoursRecord> records;
  final DateTime selectedDate;
  final LoginHoursDisplayService displayService;
  final bool canEdit;

  static const _headerStyle = TextStyle(fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No login hours data for this date.\n'
              'Data appears after HR uploads attendance via Create Attendance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }

    final headerColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.08);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: headerColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: const Row(
              children: [
                SizedBox(width: 36, child: Text('S No.', style: _headerStyle)),
                Expanded(
                  flex: 3,
                  child: Text('Employee Name', style: _headerStyle),
                ),
                SizedBox(width: 64, child: Text('In', style: _headerStyle)),
                SizedBox(width: 64, child: Text('Out', style: _headerStyle)),
                SizedBox(
                  width: 72,
                  child: Text('Duration', style: _headerStyle),
                ),
                SizedBox(width: 64, child: Text('Status', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Remarks', style: _headerStyle)),
                SizedBox(width: 36),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              interactive: true,
              child: ListView.separated(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: records.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final record = records[index];
                  final display = displayService.format(
                    record: record,
                    selectedDate: selectedDate,
                  );

                  return InkWell(
                    onTap: canEdit
                        ? () => _showEditDialog(context, ref, record, display)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 36, child: Text('${index + 1}')),
                          Expanded(flex: 3, child: Text(record.employeeName)),
                          SizedBox(width: 64, child: Text(display.inTime)),
                          SizedBox(width: 64, child: Text(display.outTime)),
                          SizedBox(width: 72, child: Text(display.duration)),
                          SizedBox(width: 64, child: Text(display.status)),
                          Expanded(flex: 2, child: Text(display.remarks)),
                          if (canEdit)
                            SizedBox(
                              width: 36,
                              child: IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showEditDialog(
                                  context,
                                  ref,
                                  record,
                                  display,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 36),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    LoginHoursRecord record,
    ({
      String inTime,
      String outTime,
      String duration,
      String status,
      String remarks,
    })
    display,
  ) async {
    final inController = TextEditingController(text: display.inTime);
    final outController = TextEditingController(
      text: record.lastOut ?? display.outTime,
    );
    final statusController = TextEditingController(text: display.status);
    final remarksController = TextEditingController(text: display.remarks);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit — ${record.employeeName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: inController,
                decoration: const InputDecoration(
                  labelText: 'In Time',
                  hintText: 'e.g. 09:05',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: outController,
                decoration: const InputDecoration(
                  labelText: 'Out Time',
                  hintText: 'e.g. 18:10',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  hintText: 'e.g. P, L, Half Day',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Half Day, Forgot Punch, etc.',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final inText = inController.text;
    final outText = outController.text;
    final statusText = statusController.text;
    final remarksText = remarksController.text;

    inController.dispose();
    outController.dispose();
    statusController.dispose();
    remarksController.dispose();

    if (saved != true || !context.mounted) return;

    await ref
        .read(loginHoursEditControllerProvider.notifier)
        .saveManualEdit(
          record: record,
          firstIn: inText,
          lastOut: outText,
          status: statusText,
          remarks: remarksText,
        );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/utils/file_download_helper.dart';
import 'package:hr_portal/core/widgets/error_view.dart';
import 'package:hr_portal/features/attendance/presentation/attendance_calendar.dart';
import 'package:hr_portal/providers/monthly_attendance_matrix_providers.dart';
import 'package:hr_portal/services/monthly_attendance_matrix_builder.dart';
import 'package:intl/intl.dart';

class MonthlyAttendancePage extends ConsumerWidget {
  const MonthlyAttendancePage({super.key, this.embedded = false});

  /// When true, renders only the body for use inside AdminShell.
  final bool embedded;

  static const _editableStatuses = <String>[
    AttendanceStatus.present,
    AttendanceStatus.latePunch,
    AttendanceStatus.leave,
    AttendanceStatus.halfLeave,
    AttendanceStatus.shortLeave,
    AttendanceStatus.unpaidLeave,
    AttendanceStatus.absent,
    AttendanceStatus.wfh,
    '-',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedMonthlyAttendanceMonthProvider);
    final matrixAsync = ref.watch(monthlyAttendanceMatrixProvider);
    final isSaving = ref.watch(monthlyAttendanceEditControllerProvider).isLoading;

    ref.listen(monthlyAttendanceEditControllerProvider, (previous, next) {
      if (next.hasValue && !next.isLoading && previous?.isLoading == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monthly attendance updated.')),
        );
      }
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(monthlyAttendanceErrorMessage(next.error!)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (embedded) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Attendance',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View and edit the combined employee attendance grid, then export to Excel.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: matrixAsync.maybeWhen(
                  data: (matrix) => matrix.rows.isEmpty
                      ? null
                      : () => _downloadExcel(context, ref, matrix),
                  orElse: () => null,
                ),
                icon: const Icon(Icons.download),
                label: const Text('Download'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Month',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickMonth(context, ref, selected),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    DateFormat(
                      'MMMM yyyy',
                    ).format(DateTime(selected.year, selected.month)),
                  ),
                ),
                const Spacer(),
                if (!embedded)
                  FilledButton.icon(
                    onPressed: matrixAsync.maybeWhen(
                      data: (matrix) => matrix.rows.isEmpty
                          ? null
                          : () => _downloadExcel(context, ref, matrix),
                      orElse: () => null,
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Stack(
            children: [
              matrixAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  message: monthlyAttendanceErrorMessage(error),
                  onRetry: () =>
                      ref.invalidate(monthlyAttendanceMatrixProvider),
                ),
                data: (matrix) => _MonthlyAttendanceTable(
                  matrix: matrix,
                  onEditStatus: (row, dayColumn) =>
                      _editStatus(context, ref, row, dayColumn),
                  onEditNotes: (row) =>
                      _editNotes(context, ref, matrix, row),
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
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Attendance')),
      body: Padding(padding: const EdgeInsets.all(16), child: body),
    );
  }

  Future<void> _pickMonth(
    BuildContext context,
    WidgetRef ref,
    SelectedAttendanceMonth selected,
  ) async {
    var year = selected.year;
    var month = selected.month;
    final now = DateTime.now();
    final years = List.generate(now.year - 2023, (i) => 2024 + i)
      ..add(now.year + 1);

    final picked = await showDialog<SelectedAttendanceMonth>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select month'),
              content: Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: month,
                          isExpanded: true,
                          items: [
                            for (var m = 1; m <= 12; m++)
                              DropdownMenuItem(
                                value: m,
                                child: Text(
                                  DateFormat('MMMM').format(DateTime(2024, m)),
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => month = value);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: year,
                          isExpanded: true,
                          items: [
                            for (final y in years)
                              DropdownMenuItem(value: y, child: Text('$y')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => year = value);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    SelectedAttendanceMonth(year: year, month: month),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null) return;
    ref.read(selectedMonthlyAttendanceMonthProvider.notifier).state = picked;
  }

  Future<void> _downloadExcel(
    BuildContext context,
    WidgetRef ref,
    MonthlyAttendanceMatrix matrix,
  ) async {
    final exporter = ref.read(monthlyAttendanceExcelExporterProvider);
    final saved = await FileDownloadHelper.saveBytes(
      bytes: exporter.export(matrix),
      fileName: exporter.suggestedFileName(matrix),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Monthly attendance Excel downloaded.'
              : 'Download cancelled.',
        ),
      ),
    );
  }

  Future<void> _editStatus(
    BuildContext context,
    WidgetRef ref,
    MonthlyAttendanceMatrixRow row,
    MonthlyAttendanceDayColumn dayColumn,
  ) async {
    final current = row.statusForDay(dayColumn.day);
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(
            '${row.employeeName} — ${dayColumn.day} ${DateFormat('MMM').format(dayColumn.date)}',
          ),
          children: [
            for (final status in _editableStatuses)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(status),
                child: Row(
                  children: [
                    if (status != '-')
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AttendanceCalendar.statusColor(status),
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        status == '-'
                            ? 'Clear / N/A (-)'
                            : '$status — ${AttendanceStatus.labels[status] ?? status}',
                        style: TextStyle(
                          fontWeight: status == current
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (status == current) const Icon(Icons.check, size: 18),
                  ],
                ),
              ),
          ],
        );
      },
    );

    if (selected == null || selected == current) return;
    await ref
        .read(monthlyAttendanceEditControllerProvider.notifier)
        .updateStatus(
          employeeName: row.employeeName,
          employeeEmail: row.employeeEmail,
          date: dayColumn.date,
          status: selected,
        );
  }

  Future<void> _editNotes(
    BuildContext context,
    WidgetRef ref,
    MonthlyAttendanceMatrix matrix,
    MonthlyAttendanceMatrixRow row,
  ) async {
    final remarksController = TextEditingController(text: row.remarks);
    final referenceController = TextEditingController(text: row.reference);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Notes — ${row.employeeName}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference',
                    border: OutlineInputBorder(),
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
        );
      },
    );

    final remarks = remarksController.text.trim();
    final reference = referenceController.text.trim();
    remarksController.dispose();
    referenceController.dispose();

    if (saved != true) return;
    if (remarks == row.remarks && reference == row.reference) return;

    await ref
        .read(monthlyAttendanceEditControllerProvider.notifier)
        .updateNotes(
          employeeName: row.employeeName,
          employeeEmail: row.employeeEmail,
          year: matrix.year,
          month: matrix.month,
          remarks: remarks,
          reference: reference,
        );
  }
}

class _MonthlyAttendanceTable extends StatelessWidget {
  const _MonthlyAttendanceTable({
    required this.matrix,
    required this.onEditStatus,
    required this.onEditNotes,
  });

  final MonthlyAttendanceMatrix matrix;
  final void Function(
    MonthlyAttendanceMatrixRow row,
    MonthlyAttendanceDayColumn dayColumn,
  )
  onEditStatus;
  final void Function(MonthlyAttendanceMatrixRow row) onEditNotes;

  static const double _serialWidth = 48;
  static const double _nameWidth = 160;
  static const double _dayWidth = 44;
  static const double _notesWidth = 140;
  static const double _rowHeight = 40;
  static const double _headerHeight = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayCount = matrix.dayColumns.length;
    final scrollWidth =
        _serialWidth +
        _nameWidth +
        (dayCount * _dayWidth) +
        (_notesWidth * 2);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: scrollWidth,
                      height: constraints.maxHeight,
                      child: Column(
                        children: [
                          _buildHeader(theme),
                          Expanded(
                            child: ListView.builder(
                              itemCount: matrix.rows.length,
                              itemBuilder: (context, index) {
                                final row = matrix.rows[index];
                                final stripe = index.isOdd
                                    ? theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.35)
                                    : theme.colorScheme.surface;
                                return Container(
                                  height: _rowHeight,
                                  color: stripe,
                                  child: Row(
                                    children: [
                                      _cell(
                                        width: _serialWidth,
                                        child: Text(
                                          '${row.serial}',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                      _cell(
                                        width: _nameWidth,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          row.employeeName,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      for (final dayColumn
                                          in matrix.dayColumns)
                                        _statusCell(
                                          theme: theme,
                                          status: row.statusForDay(
                                            dayColumn.day,
                                          ),
                                          weekend:
                                              dayColumn.date.weekday ==
                                                  DateTime.saturday ||
                                              dayColumn.date.weekday ==
                                                  DateTime.sunday,
                                          onTap: () =>
                                              onEditStatus(row, dayColumn),
                                        ),
                                      _notesCell(
                                        theme: theme,
                                        text: row.remarks,
                                        onTap: () => onEditNotes(row),
                                      ),
                                      _notesCell(
                                        theme: theme,
                                        text: row.reference,
                                        onTap: () => onEditNotes(row),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final entry in AttendanceStatus.labels.entries)
                  _LegendChip(
                    color: AttendanceCalendar.statusColor(entry.key),
                    label: '${entry.key} ${entry.value}',
                  ),
                const _LegendChip(color: Colors.transparent, label: '- N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final headerColor = theme.colorScheme.primaryContainer.withValues(
      alpha: 0.55,
    );
    return Container(
      height: _headerHeight,
      color: headerColor,
      child: Row(
        children: [
          _cell(
            width: _serialWidth,
            child: Text(
              'S.no',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _cell(
            width: _nameWidth,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              matrix.monthLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final dayColumn in matrix.dayColumns)
            _cell(
              width: _dayWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${dayColumn.day}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    dayColumn.weekdayLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _cell(
            width: _notesWidth,
            child: Text(
              'Remarks',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _cell(
            width: _notesWidth,
            child: Text(
              'Reference',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCell({
    required ThemeData theme,
    required String status,
    required bool weekend,
    required VoidCallback onTap,
  }) {
    final hasStatus = status.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: _dayWidth,
        height: _rowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
          ),
          color: weekend
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : null,
        ),
        child: hasStatus
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AttendanceCalendar.statusColor(
                    status,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AttendanceCalendar.statusColor(status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Text(
                weekend ? '' : '-',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
      ),
    );
  }

  Widget _notesCell({
    required ThemeData theme,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: _notesWidth,
        height: _rowHeight,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
          ),
        ),
        child: Text(
          text.isEmpty ? 'Tap to edit' : text,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
            color: text.isEmpty
                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _cell({
    required double width,
    required Widget child,
    Alignment alignment = Alignment.center,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.black12),
        ),
      ),
      child: child,
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color == Colors.transparent
                ? Theme.of(context).colorScheme.outlineVariant
                : color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

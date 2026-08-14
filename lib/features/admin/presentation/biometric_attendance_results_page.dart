import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/core/utils/file_download_helper.dart';
import 'package:hr_portal/core/widgets/app_logo.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/providers/biometric_attendance_providers.dart';
import 'package:hr_portal/services/attendance_status_calculator.dart';
import 'package:intl/intl.dart';

class BiometricAttendanceResultsPage extends ConsumerStatefulWidget {
  const BiometricAttendanceResultsPage({super.key});

  @override
  ConsumerState<BiometricAttendanceResultsPage> createState() =>
      _BiometricAttendanceResultsPageState();
}

class _BiometricAttendanceResultsPageState
    extends ConsumerState<BiometricAttendanceResultsPage> {
  static const _statusCalculator = AttendanceStatusCalculator();

  String _search = '';
  String? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(biometricProcessResultProvider);
    if (result == null) {
      return Scaffold(
        appBar: AppBar(
          title: const AppBarTitle(subtitle: 'Biometric Attendance'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.adminAttendance),
          ),
        ),
        body: const Center(child: Text('No biometric data to display.')),
      );
    }

    final calendarSync = ref.watch(biometricCalendarSyncResultProvider);
    final dateFormat = DateFormat('dd MMM yyyy');
    final dates =
        result.records.map((record) => _dateKey(record.date)).toSet().toList()
          ..sort();

    final filtered = result.records.where((record) {
      final matchesSearch =
          _search.isEmpty ||
          record.employeeName.toLowerCase().contains(_search.toLowerCase()) ||
          record.employeeId.contains(_search);
      final matchesDate =
          _selectedDate == null || _dateKey(record.date) == _selectedDate;
      return matchesSearch && matchesDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(subtitle: 'Biometric Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.adminAttendance),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _downloadExcel(result),
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text(
              'Download',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton.icon(
            onPressed: () => _copyCsv(result),
            icon: const Icon(Icons.copy, color: Colors.white),
            label: const Text(
              'Copy CSV',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ResponsivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.fileName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${dateFormat.format(result.periodStart)} – '
                      '${dateFormat.format(result.periodEnd)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Present: ${result.presentCount} · Absent (A): '
                      '${result.absentCount} · Week off: ${result.weekOffCount}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (calendarSync != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        calendarSync.summary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: calendarSync.unmatchedNames.isEmpty
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'First IN → Last OUT duration per employee per weekday. '
                      '≥8h Present (or Late Punch / LP if first IN is '
                      '12:11–12:30), 6–8h Short Leave (SL), 4–6h Half Day (HL), '
                      '<4h Absent. Intermediate punches are ignored. '
                      'A = no biometric record. Saturday and Sunday = weekoff.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search employee or ID',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        setState(() => _search = value.trim()),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedDate,
                    decoration: const InputDecoration(labelText: 'Date'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All dates'),
                      ),
                      ...dates.map(
                        (date) => DropdownMenuItem<String?>(
                          value: date,
                          child: Text(date),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedDate = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching records.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final record = filtered[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                record.isWeekOff ? 'WO' : record.status,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            title: Text(
                              '${record.employeeName} (${record.employeeId})',
                            ),
                            subtitle: Text(_dateKey(record.date)),
                            trailing:
                                record.isWeekOff || record.isWfh
                                ? Chip(label: Text(record.status))
                                : _PunchSummary(
                                    firstIn: record.firstIn,
                                    lastOut: record.lastOut,
                                    status: record.status,
                                    duration: _statusCalculator.formatDuration(
                                      firstIn: record.firstIn,
                                      lastOut: record.lastOut,
                                    ),
                                  ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadExcel(BiometricProcessResult result) async {
    final service = ref.read(biometricAttendanceServiceProvider);
    final bytes = service.toExcelBytes(result);
    final fileName = service.excelFileName(result);

    final saved = await FileDownloadHelper.saveBytes(
      bytes: bytes,
      fileName: fileName,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Attendance Excel downloaded.' : 'Download cancelled.',
        ),
      ),
    );
  }

  Future<void> _copyCsv(BiometricProcessResult result) async {
    final csv = ref.read(biometricAttendanceServiceProvider).toCsv(result);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard.')));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _PunchSummary extends StatelessWidget {
  const _PunchSummary({
    required this.firstIn,
    required this.lastOut,
    required this.status,
    required this.duration,
  });

  final String? firstIn;
  final String? lastOut;
  final String status;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${firstIn ?? '--'} → ${lastOut ?? '--'}',
          style: style,
        ),
        Text(
          '$duration · $status',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

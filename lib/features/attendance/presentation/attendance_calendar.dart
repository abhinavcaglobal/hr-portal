import 'package:flutter/material.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:intl/intl.dart';

class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({
    super.key,
    required this.selectedMonth,
    required this.records,
    required this.onMonthChanged,
  });

  final DateTime selectedMonth;
  final List<AttendanceRecord> records;
  final ValueChanged<DateTime> onMonthChanged;

  static Color statusColor(String status) {
    return switch (status.toUpperCase()) {
      AttendanceStatus.present => const Color(0xFF2E7D32),
      AttendanceStatus.absent => const Color(0xFFD32F2F),
      AttendanceStatus.wfh => const Color(0xFF0288D1),
      AttendanceStatus.leave => const Color(0xFFC62828),
      AttendanceStatus.halfLeave => const Color(0xFFF57C00),
      AttendanceStatus.shortLeave => const Color(0xFF7B1FA2),
      _ => const Color(0xFF9E9E9E),
    };
  }

  Map<int, String> get _recordsByDay {
    final map = <int, String>{};
    for (final record in records) {
      if (record.date.year == selectedMonth.year &&
          record.date.month == selectedMonth.month) {
        map[record.date.day] = record.status;
      }
    }
    return map;
  }

  void _goToPreviousMonth() {
    onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month - 1, 1));
  }

  void _goToNextMonth() {
    onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month + 1, 1));
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth);
    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    ).weekday;
    final leadingEmpty = firstWeekday - 1;
    final recordsByDay = _recordsByDay;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: _goToPreviousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              monthLabel,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: _goToNextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.1,
          ),
          itemCount: leadingEmpty + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingEmpty) {
              return const SizedBox.shrink();
            }

            final day = index - leadingEmpty + 1;
            final isToday = _isToday(day);
            final isUpcoming = _isUpcoming(day);
            final status = isUpcoming ? null : recordsByDay[day];

            return _DayCell(day: day, status: status, isToday: isToday);
          },
        ),
      ],
    );
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    return now.year == selectedMonth.year &&
        now.month == selectedMonth.month &&
        now.day == day;
  }

  bool _isUpcoming(int day) {
    final now = DateTime.now();
    final cellDate = DateTime(selectedMonth.year, selectedMonth.month, day);
    final today = DateTime(now.year, now.month, now.day);
    return cellDate.isAfter(today);
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.status,
    required this.isToday,
  });

  final int day;
  final String? status;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final hasStatus = status != null && status!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: hasStatus
            ? AttendanceCalendar.statusColor(status!)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasStatus
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (hasStatus) ...[
            const SizedBox(height: 2),
            Text(
              status!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

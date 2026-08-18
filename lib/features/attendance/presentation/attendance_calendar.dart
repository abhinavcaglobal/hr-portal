import 'package:flutter/material.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/services/leave_request_rules.dart';
import 'package:intl/intl.dart';

class CalendarLeaveOverlay {
  const CalendarLeaveOverlay({
    required this.day,
    required this.status,
    required this.duration,
    this.halfDayType,
    this.fromTime,
    this.toTime,
    this.isUnpaid = false,
    this.adminComment,
  });

  final int day;
  final String status;
  final String duration;
  final String? halfDayType;
  final String? fromTime;
  final String? toTime;
  final bool isUnpaid;
  final String? adminComment;
}

class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({
    super.key,
    required this.selectedMonth,
    required this.records,
    required this.onMonthChanged,
    this.leaveOverlays = const [],
    this.onDaySelected,
  });

  final DateTime selectedMonth;
  final List<AttendanceRecord> records;
  final ValueChanged<DateTime> onMonthChanged;
  final List<CalendarLeaveOverlay> leaveOverlays;
  final ValueChanged<DateTime>? onDaySelected;

  static const _rules = LeaveRequestRules();

  static Color statusColor(String status) {
    return switch (status.toUpperCase()) {
      AttendanceStatus.present => const Color(0xFF2E7D32),
      AttendanceStatus.absent => const Color(0xFFD32F2F),
      AttendanceStatus.wfh => const Color(0xFF0288D1),
      AttendanceStatus.leave => const Color(0xFFC62828),
      AttendanceStatus.halfLeave => const Color(0xFFF57C00),
      AttendanceStatus.shortLeave => const Color(0xFF7B1FA2),
      AttendanceStatus.unpaidLeave => const Color(0xFF6A1B9A),
      _ => const Color(0xFF9E9E9E),
    };
  }

  static Color overlayColor(String status) {
    return switch (status) {
      // Light blue — unused by attendance statuses.
      LeaveRequestStatus.pending => const Color(0xFF4FC3F7),
      // Amber / gold yellow — distinct from Present green and Half Leave orange.
      LeaveRequestStatus.approved => const Color(0xFFFFB300),
      LeaveRequestStatus.declined => const Color(0xFF757575),
      _ => const Color(0xFF9E9E9E),
    };
  }

  static bool usesDarkOverlayText(String status) {
    return status == LeaveRequestStatus.approved;
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

  Map<int, CalendarLeaveOverlay> get _overlaysByDay {
    final map = <int, CalendarLeaveOverlay>{};
    for (final overlay in leaveOverlays) {
      map[overlay.day] = overlay;
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
    final overlaysByDay = _overlaysByDay;

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
            childAspectRatio: 0.82,
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
            final overlay = overlaysByDay[day];
            final cellDate = DateTime(
              selectedMonth.year,
              selectedMonth.month,
              day,
            );

            return _DayCell(
              day: day,
              status: status,
              overlayLabel: overlay == null
                  ? null
                  : _rules.calendarOverlayLabel(
                      status: overlay.status,
                      duration: overlay.duration,
                      isUnpaid: overlay.isUnpaid,
                    ),
              overlayColor: overlay == null
                  ? null
                  : overlayColor(overlay.status),
              overlayDetail: overlay == null
                  ? null
                  : _overlayDetail(overlay),
              darkOverlayText: overlay != null &&
                  usesDarkOverlayText(overlay.status),
              isToday: isToday,
              onTap: onDaySelected == null
                  ? null
                  : () => onDaySelected!(cellDate),
            );
          },
        ),
      ],
    );
  }

  String? _overlayDetail(CalendarLeaveOverlay overlay) {
    if (overlay.status == LeaveRequestStatus.declined) return null;
    if (overlay.isUnpaid && overlay.status == LeaveRequestStatus.approved) {
      return UnpaidLeave.employeeNote;
    }
    if (overlay.adminComment != null && overlay.adminComment!.trim().isNotEmpty) {
      return 'Admin: ${overlay.adminComment!.trim()}';
    }
    if (overlay.duration == LeaveDuration.halfDay &&
        overlay.halfDayType != null) {
      return HalfDayType.labels[overlay.halfDayType];
    }
    if (overlay.duration == LeaveDuration.shortLeave) {
      return _rules.displayTimeRange(overlay.fromTime, overlay.toTime);
    }
    return null;
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
    this.overlayLabel,
    this.overlayColor,
    this.overlayDetail,
    this.darkOverlayText = false,
    this.onTap,
  });

  final int day;
  final String? status;
  final bool isToday;
  final String? overlayLabel;
  final Color? overlayColor;
  final String? overlayDetail;
  final bool darkOverlayText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasStatus = status != null && status!.isNotEmpty;
    final hasOverlay = overlayLabel != null && overlayLabel!.isNotEmpty;
    final background = hasOverlay && overlayColor != null
        ? overlayColor
        : hasStatus
        ? AttendanceCalendar.statusColor(status!)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final onColor = hasOverlay
        ? (darkOverlayText ? const Color(0xFF3E2723) : Colors.white)
        : hasStatus
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onColor,
                ),
              ),
              if (hasStatus && !hasOverlay) ...[
                const SizedBox(height: 2),
                Text(
                  status!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: onColor,
                  ),
                ),
              ],
              if (hasStatus && hasOverlay)
                Text(
                  status!,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: onColor,
                  ),
                ),
              if (hasOverlay) ...[
                Text(
                  overlayLabel!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: onColor,
                    height: 1.1,
                  ),
                ),
                if (overlayDetail != null && overlayDetail != '-')
                  Text(
                    overlayDetail!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 7,
                      color: onColor,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

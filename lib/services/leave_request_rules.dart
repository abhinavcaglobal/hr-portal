import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';

class LeaveRequestValidationException implements Exception {
  const LeaveRequestValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Pure leave-request rules (no Firebase). Used by the UI and by tests.
class LeaveRequestRules {
  const LeaveRequestRules();

  double deductionFor(String duration) => LeaveDuration.deductionFor(duration);

  String attendanceStatusFor(String duration) => switch (duration) {
    LeaveDuration.fullDay => AttendanceStatus.leave,
    LeaveDuration.halfDay => AttendanceStatus.halfLeave,
    LeaveDuration.shortLeave => AttendanceStatus.shortLeave,
    _ => throw const LeaveRequestValidationException(
      'Select a valid leave duration.',
    ),
  };

  String durationShortLabel(String duration) =>
      LeaveDuration.shortLabels[duration] ?? duration;

  String calendarOverlayLabel({
    required String status,
    required String duration,
    bool isUnpaid = false,
  }) {
    if (status == LeaveRequestStatus.declined) {
      return 'Declined — Leave';
    }
    if (status == LeaveRequestStatus.approved && isUnpaid) {
      return 'Approved — Unpaid Leave';
    }
    final durationLabel = durationShortLabel(duration);
    if (status == LeaveRequestStatus.approved) {
      return 'Approved — $durationLabel';
    }
    return 'Requested — $durationLabel';
  }

  bool isUnpaidLeave(double currentBalance, double requestedDeduction) {
    return currentBalance <= 0 || currentBalance < requestedDeduction;
  }

  bool isActiveStatus(String status) =>
      status == LeaveRequestStatus.pending ||
      status == LeaveRequestStatus.approved;

  /// Minutes from a `HH:mm` (or `h:mm a`) string. Returns null if invalid.
  int? minutesFromTimeLabel(String value) {
    final trimmed = value.trim();
    final twentyFour = RegExp(r'^(\d{1,2}):(\d{2})$');
    final match24 = twentyFour.firstMatch(trimmed);
    if (match24 != null) {
      final h = int.parse(match24.group(1)!);
      final m = int.parse(match24.group(2)!);
      if (h < 0 || h > 23 || m < 0 || m > 59) return null;
      return h * 60 + m;
    }

    final twelve = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$');
    final match12 = twelve.firstMatch(trimmed);
    if (match12 != null) {
      var h = int.parse(match12.group(1)!);
      final m = int.parse(match12.group(2)!);
      final period = match12.group(3)!.toUpperCase();
      if (h < 1 || h > 12 || m < 0 || m > 59) return null;
      if (period == 'AM') {
        if (h == 12) h = 0;
      } else {
        if (h != 12) h += 12;
      }
      return h * 60 + m;
    }
    return null;
  }

  String formatTimeOfDay(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String displayTimeRange(String? fromTime, String? toTime) {
    if (fromTime == null ||
        fromTime.isEmpty ||
        toTime == null ||
        toTime.isEmpty) {
      return '-';
    }
    return '$fromTime - $toTime';
  }

  String halfOrTimeDetails({
    required String duration,
    String? halfDayType,
    String? fromTime,
    String? toTime,
  }) {
    if (duration == LeaveDuration.halfDay) {
      return HalfDayType.labels[halfDayType] ?? '-';
    }
    if (duration == LeaveDuration.shortLeave) {
      return displayTimeRange(fromTime, toTime);
    }
    return '-';
  }

  void validateSubmit({
    required String leaveType,
    required String leaveDuration,
    String? halfDayType,
    String? fromTime,
    String? toTime,
  }) {
    if (leaveType.trim().isEmpty) {
      throw const LeaveRequestValidationException('Select a leave type.');
    }
    if (!LeaveCategory.all.contains(leaveType)) {
      throw const LeaveRequestValidationException('Select a valid leave type.');
    }
    if (!LeaveDuration.all.contains(leaveDuration)) {
      throw const LeaveRequestValidationException('Select a leave duration.');
    }

    final deduction = LeaveDuration.deductionFor(leaveDuration);
    if (deduction <= 0) {
      throw const LeaveRequestValidationException(
        'Leave deduction must be greater than zero.',
      );
    }

    if (leaveDuration == LeaveDuration.halfDay) {
      if (halfDayType == null || !HalfDayType.all.contains(halfDayType)) {
        throw const LeaveRequestValidationException(
          'Select First Half or Second Half.',
        );
      }
    }

    if (leaveDuration == LeaveDuration.shortLeave) {
      if (fromTime == null ||
          fromTime.trim().isEmpty ||
          toTime == null ||
          toTime.trim().isEmpty) {
        throw const LeaveRequestValidationException(
          'Enter From Time and To Time for Short Leave.',
        );
      }
      final fromMinutes = minutesFromTimeLabel(fromTime);
      final toMinutes = minutesFromTimeLabel(toTime);
      if (fromMinutes == null || toMinutes == null) {
        throw const LeaveRequestValidationException(
          'Enter a valid From Time and To Time.',
        );
      }
      if (fromMinutes >= toMinutes) {
        throw const LeaveRequestValidationException(
          'From Time must be earlier than To Time.',
        );
      }
    }
  }
}

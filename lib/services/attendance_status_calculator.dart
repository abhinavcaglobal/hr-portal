import 'package:hr_portal/core/constants/attendance_status.dart';

/// Calculates daily attendance status from first IN and last OUT times.
///
/// Status is based on total duration (Last OUT − First IN), not fixed clock
/// times. Intermediate punches are ignored by callers that already supply
/// earliest IN and latest OUT for the employee/date.
///
/// Thresholds:
/// - duration >= 8h → Present (P), or Late Punch (LP) when first IN is
///   between 12:11 and 12:30 inclusive
/// - 6h <= duration < 8h → Short Leave (SL)
/// - 4h <= duration < 6h → Half Leave / Half Day (HL)
/// - duration < 4h → Absent (A)
///
/// Incomplete punches (IN without OUT, or OUT without IN) do not invent a
/// missing time. They keep the existing incomplete-day behavior so HR can
/// review and manually override when needed. A late first IN alone is marked
/// Late Punch.
class AttendanceStatusCalculator {
  const AttendanceStatusCalculator();

  static const int presentMinutes = 8 * 60;
  static const int shortLeaveMinutes = 6 * 60;
  static const int halfDayMinutes = 4 * 60;

  /// Inclusive late-punch arrival window: 12:11 PM – 12:30 PM.
  static const int latePunchStartMinutes = 12 * 60 + 11;
  static const int latePunchEndMinutes = 12 * 60 + 30;

  String calculate({String? firstIn, String? lastOut}) {
    final hasIn = firstIn != null && firstIn.trim().isNotEmpty;
    final hasOut = lastOut != null && lastOut.trim().isNotEmpty;

    if (!hasIn && !hasOut) {
      return AttendanceStatus.absent;
    }

    // Incomplete biometric day — do not invent the missing punch.
    if (!hasIn || !hasOut) {
      if (hasIn && _isLatePunchArrival(firstIn)) {
        return AttendanceStatus.latePunch;
      }
      return AttendanceStatus.present;
    }

    final duration = durationMinutes(firstIn: firstIn, lastOut: lastOut);
    if (duration == null || duration < 0) {
      return AttendanceStatus.present;
    }

    if (duration >= presentMinutes) {
      if (_isLatePunchArrival(firstIn)) {
        return AttendanceStatus.latePunch;
      }
      return AttendanceStatus.present;
    }
    if (duration >= shortLeaveMinutes) {
      return AttendanceStatus.shortLeave;
    }
    if (duration >= halfDayMinutes) {
      return AttendanceStatus.halfLeave;
    }
    return AttendanceStatus.absent;
  }

  /// Minutes between first IN and last OUT, or null if either time is missing
  /// or unparseable.
  int? durationMinutes({String? firstIn, String? lastOut}) {
    final inMinutes = timeToMinutes(firstIn);
    final outMinutes = timeToMinutes(lastOut);
    if (inMinutes == null || outMinutes == null) return null;
    return outMinutes - inMinutes;
  }

  /// Minutes since midnight for an `HH:mm` time, or null when unparseable.
  int? timeToMinutes(String? time) => _toMinutes(time);

  /// Human-readable duration such as `8h 51m`, or `-` when unknown.
  String formatDuration({String? firstIn, String? lastOut}) {
    final minutes = durationMinutes(firstIn: firstIn, lastOut: lastOut);
    if (minutes == null || minutes < 0) return '-';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  String arrivalStatus(String firstIn) {
    if (firstIn.trim().isEmpty) {
      return AttendanceStatus.absent;
    }
    if (_isLatePunchArrival(firstIn)) {
      return AttendanceStatus.latePunch;
    }
    return AttendanceStatus.present;
  }

  String departureStatus(String lastOut) {
    if (lastOut.trim().isEmpty) {
      return AttendanceStatus.absent;
    }
    return AttendanceStatus.present;
  }

  bool _isLatePunchArrival(String? firstIn) {
    final minutes = _toMinutes(firstIn);
    if (minutes == null) return false;
    return minutes >= latePunchStartMinutes && minutes <= latePunchEndMinutes;
  }

  int? _toMinutes(String? time) {
    if (time == null) return null;
    final trimmed = time.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }
}

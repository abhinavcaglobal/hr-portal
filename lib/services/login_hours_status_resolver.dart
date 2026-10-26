import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/services/attendance_status_calculator.dart';

/// Resolves the status that should be stored after an HR login-hours edit.
///
/// Time-based statuses (P / LP / SL / HL / A) are always recalculated from
/// In/Out so the employee calendar stays aligned with punch times. Explicit
/// non-time statuses (L, WFH, weekoff) are preserved when HR sets them.
class LoginHoursStatusResolver {
  const LoginHoursStatusResolver({
    this.statusCalculator = const AttendanceStatusCalculator(),
  });

  final AttendanceStatusCalculator statusCalculator;

  static const _preservedStatuses = {
    AttendanceStatus.leave,
    AttendanceStatus.wfh,
    'WEEKOFF',
  };

  String resolve({
    required String firstIn,
    required String lastOut,
    required String statusInput,
  }) {
    final normalizedIn = _normalizeTime(firstIn);
    final normalizedOut = _normalizeTime(lastOut);
    final trimmedStatus = statusInput.trim();
    final upperStatus = trimmedStatus.toUpperCase();

    if (upperStatus == 'WEEKOFF') {
      return 'weekoff';
    }
    if (_preservedStatuses.contains(upperStatus)) {
      return upperStatus;
    }

    final hasTimes = normalizedIn.isNotEmpty || normalizedOut.isNotEmpty;
    if (hasTimes) {
      return statusCalculator.calculate(
        firstIn: normalizedIn.isEmpty ? null : normalizedIn,
        lastOut: normalizedOut.isEmpty ? null : normalizedOut,
      );
    }

    if (trimmedStatus.isNotEmpty) {
      return trimmedStatus;
    }
    return AttendanceStatus.absent;
  }

  String _normalizeTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return '';
    }
    return trimmed;
  }
}

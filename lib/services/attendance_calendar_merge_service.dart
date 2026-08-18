import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/services/attendance_status_calculator.dart';

/// Combines uploaded attendance sheet records with login hours so the calendar
/// shows Present/Absent as soon as a login time is recorded.
///
/// Login hours drive P/A. Leave marked on the attendance sheet (L, HL, SL)
/// always wins, since biometric data cannot tell a leave day from an absence.
class AttendanceCalendarMergeService {
  const AttendanceCalendarMergeService({
    this.statusCalculator = const AttendanceStatusCalculator(),
  });

  final AttendanceStatusCalculator statusCalculator;

  static const Set<String> _leaveStatuses = {
    AttendanceStatus.leave,
    AttendanceStatus.halfLeave,
    AttendanceStatus.shortLeave,
    AttendanceStatus.unpaidLeave,
  };

  List<AttendanceRecord> merge({
    required String employeeName,
    required String employeeEmail,
    required List<AttendanceRecord> stored,
    required List<LoginHoursRecord> loginHours,
    DateTime? today,
  }) {
    final todayDate = DateTime(
      (today ?? DateTime.now()).year,
      (today ?? DateTime.now()).month,
      (today ?? DateTime.now()).day,
    );
    final byDate = <String, AttendanceRecord>{};

    for (final record in loginHours) {
      if (_isUpcoming(record.date, todayDate)) continue;

      final status = _statusFor(record);
      if (status == null) continue;

      byDate[_dateKey(record.date)] = AttendanceRecord(
        employeeName: employeeName,
        employeeEmail: employeeEmail,
        date: record.date,
        status: status,
      );
    }

    for (final record in stored) {
      if (_isUpcoming(record.date, todayDate)) continue;

      final key = _dateKey(record.date);
      final fromLoginHours = byDate[key];
      if (fromLoginHours == null ||
          _leaveStatuses.contains(record.status.toUpperCase())) {
        byDate[key] = record;
      }
    }

    return byDate.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  bool _isUpcoming(DateTime date, DateTime today) {
    final day = DateTime(date.year, date.month, date.day);
    return day.isAfter(today);
  }

  String? _statusFor(LoginHoursRecord record) {
    if (record.isWeekOff) return null;

    if (record.manuallyEdited) {
      final status = record.status.trim().toUpperCase();
      return status.isEmpty ? null : status;
    }

    if (record.isLeave) return AttendanceStatus.leave;
    if (record.isWfh) return AttendanceStatus.wfh;

    final hasTimes = _hasValue(record.firstIn) || _hasValue(record.lastOut);
    if (!hasTimes && BiometricEmployeeRoster.isWfhEmployee(record.employeeId)) {
      return AttendanceStatus.wfh;
    }
    if (!hasTimes && record.status.trim().isEmpty) return null;

    return statusCalculator.calculate(
      firstIn: record.firstIn,
      lastOut: record.lastOut,
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

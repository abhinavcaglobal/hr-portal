import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/services/attendance_status_calculator.dart';

/// Formats stored login hours for display.
class LoginHoursDisplayService {
  const LoginHoursDisplayService({
    this.statusCalculator = const AttendanceStatusCalculator(),
  });

  final AttendanceStatusCalculator statusCalculator;
  ({
    String inTime,
    String outTime,
    String duration,
    String status,
    String remarks,
  })
  format({
    required LoginHoursRecord record,
    required DateTime selectedDate,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final isToday = _isSameDay(selectedDate, now);

    return (
      inTime: _displayIn(record.firstIn),
      outTime: _displayOut(record.lastOut, isToday: isToday),
      duration: statusCalculator.formatDuration(
        firstIn: record.firstIn,
        lastOut: record.lastOut,
      ),
      status: _displayStatus(record),
      remarks: record.remarks,
    );
  }

  String _displayIn(String? firstIn) {
    if (firstIn != null && firstIn.trim().isNotEmpty) {
      return firstIn;
    }
    return '-';
  }

  String _displayOut(String? lastOut, {required bool isToday}) {
    if (lastOut == null || lastOut.trim().isEmpty) {
      return '-';
    }
    if (isToday) {
      return '';
    }
    return lastOut;
  }

  String _displayStatus(LoginHoursRecord record) {
    if (record.manuallyEdited) {
      return record.status;
    }
    if (record.isWeekOff) {
      return 'weekoff';
    }
    if (record.isLeave) {
      return AttendanceStatus.leave;
    }

    final hasTimes = _hasValue(record.firstIn) || _hasValue(record.lastOut);
    if (!hasTimes && BiometricEmployeeRoster.isWfhEmployee(record.employeeId)) {
      return AttendanceStatus.wfh;
    }
    if (record.isWfh) {
      return AttendanceStatus.wfh;
    }

    return statusCalculator.calculate(
      firstIn: record.firstIn,
      lastOut: record.lastOut,
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

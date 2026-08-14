import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/models/login_hours_record.dart';

/// Builds a full employee list for Login Hours by merging Firestore data
/// with the biometric roster (same complete list as Attendance Download).
class LoginHoursMergeService {
  const LoginHoursMergeService();

  List<LoginHoursRecord> mergeForDate({
    required DateTime date,
    required List<LoginHoursRecord> stored,
  }) {
    if (stored.isEmpty) {
      return const [];
    }

    final storedByEmployeeId = {
      for (final record in stored) record.employeeId: record,
    };

    final merged = <LoginHoursRecord>[];
    for (final employee in BiometricEmployeeRoster.employees) {
      final existing = storedByEmployeeId[employee.normalizedId];
      if (existing != null) {
        merged.add(existing.copyWith(employeeName: employee.displayName));
      } else {
        merged.add(
          LoginHoursRecord(
            employeeId: employee.normalizedId,
            employeeName: employee.displayName,
            date: date,
            status: _isWeekend(date)
                ? 'weekoff'
                : (employee.isWfh ? AttendanceStatus.wfh : ''),
          ),
        );
      }
    }

    return merged;
  }

  bool _isWeekend(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
}

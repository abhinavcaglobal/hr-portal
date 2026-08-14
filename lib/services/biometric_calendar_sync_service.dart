import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/repositories/attendance_repository.dart';
import 'package:hr_portal/repositories/employee_repository.dart';

class BiometricCalendarSyncResult {
  const BiometricCalendarSyncResult({
    required this.syncedCount,
    required this.unmatchedNames,
  });

  final int syncedCount;
  final List<String> unmatchedNames;

  String get summary {
    if (unmatchedNames.isEmpty) {
      return 'Calendar updated with $syncedCount day(s).';
    }
    return 'Calendar updated with $syncedCount day(s). '
        'No portal account matched: ${unmatchedNames.join(', ')}.';
  }
}

/// Pushes biometric P/A results into the attendance collection so they appear
/// on the employee attendance calendar.
class BiometricCalendarSyncService {
  BiometricCalendarSyncService({
    required EmployeeRepository employeeRepository,
    required AttendanceRepository attendanceRepository,
  }) : _employeeRepository = employeeRepository,
       _attendanceRepository = attendanceRepository;

  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;

  Future<BiometricCalendarSyncResult> sync(
    List<BiometricDailyAttendance> records,
  ) async {
    if (records.isEmpty) {
      return const BiometricCalendarSyncResult(
        syncedCount: 0,
        unmatchedNames: [],
      );
    }

    final employees = await _employeeRepository.getAllEmployees();
    final built = buildRecords(records: records, employees: employees);

    final syncedCount = await _attendanceRepository
        .importBiometricAttendanceRecords(built.records);

    return BiometricCalendarSyncResult(
      syncedCount: syncedCount,
      unmatchedNames: built.unmatchedNames,
    );
  }

  ({List<AttendanceRecord> records, List<String> unmatchedNames}) buildRecords({
    required List<BiometricDailyAttendance> records,
    required List<Employee> employees,
  }) {
    final matches = <String, Employee>{};
    final unmatched = <String>{};
    final attendance = <AttendanceRecord>[];

    for (final record in records) {
      final status = record.status.toUpperCase();
      if (status != AttendanceStatus.present &&
          status != AttendanceStatus.absent &&
          status != AttendanceStatus.wfh) {
        continue;
      }

      final employee =
          matches[record.employeeName] ??
          _findEmployee(record.employeeName, employees);

      if (employee == null) {
        unmatched.add(record.employeeName);
        continue;
      }
      matches[record.employeeName] = employee;

      attendance.add(
        AttendanceRecord(
          employeeName: employee.name,
          employeeEmail: employee.email.trim().toLowerCase(),
          date: record.date,
          status: status,
        ),
      );
    }

    return (records: attendance, unmatchedNames: unmatched.toList()..sort());
  }

  /// Biometric names are often short (e.g. "Ritu") while portal accounts hold
  /// full names ("Ritu Sharma"), so fall back to a unique first-name match.
  Employee? _findEmployee(String biometricName, List<Employee> employees) {
    final target = _normalize(_stripWfhLabel(biometricName));
    if (target.isEmpty) return null;

    final withEmail = employees.where(
      (employee) => employee.email.trim().isNotEmpty,
    );

    for (final employee in withEmail) {
      if (_normalize(_stripWfhLabel(employee.name)) == target) {
        return employee;
      }
    }

    final prefixMatches = withEmail
        .where(
          (employee) =>
              _normalize(_stripWfhLabel(employee.name)).startsWith('$target '),
        )
        .toList();

    return prefixMatches.length == 1 ? prefixMatches.first : null;
  }

  String _stripWfhLabel(String name) {
    final trimmed = name.trim();
    final match = RegExp(
      r'^(.*?)\s*\(\s*wfh\s*\)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    return match?.group(1)?.trim() ?? trimmed;
  }

  String _normalize(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

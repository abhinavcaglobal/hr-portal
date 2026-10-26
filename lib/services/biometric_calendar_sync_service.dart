import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/repositories/attendance_repository.dart';
import 'package:hr_portal/repositories/employee_repository.dart';
import 'package:hr_portal/services/attendance_calendar_merge_service.dart';
import 'package:hr_portal/services/portal_employee_matcher.dart';

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

/// Pushes biometric / login-hours statuses into the attendance collection so
/// they appear on employee calendars and the admin monthly attendance grid.
class BiometricCalendarSyncService {
  BiometricCalendarSyncService({
    required EmployeeRepository employeeRepository,
    required AttendanceRepository attendanceRepository,
    this.matcher = const PortalEmployeeMatcher(),
    this.mergeService = const AttendanceCalendarMergeService(),
  }) : _employeeRepository = employeeRepository,
       _attendanceRepository = attendanceRepository;

  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;
  final PortalEmployeeMatcher matcher;
  final AttendanceCalendarMergeService mergeService;

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

  /// Writes calculated login-hours statuses (P/A/LP/HL/SL/WFH) into attendance
  /// for the admin monthly grid and employee calendars.
  Future<BiometricCalendarSyncResult> syncFromLoginHours(
    List<LoginHoursRecord> loginHours, {
    DateTime? today,
  }) async {
    if (loginHours.isEmpty) {
      return const BiometricCalendarSyncResult(
        syncedCount: 0,
        unmatchedNames: [],
      );
    }

    final employees = await _employeeRepository.getAllEmployees();
    final built = buildRecordsFromLoginHours(
      loginHours: loginHours,
      employees: employees,
      today: today,
    );

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
    final matches = <String, PortalEmployeeMatch>{};
    final unmatched = <String>{};
    final attendance = <AttendanceRecord>[];

    for (final record in records) {
      final status = record.status.toUpperCase();
      if (!AttendanceStatus.calendarSyncStatuses.contains(status)) {
        continue;
      }

      final employee =
          matches[record.employeeName] ??
          matcher.find(record.employeeName, employees);

      if (employee == null) {
        unmatched.add(record.employeeName);
        continue;
      }
      matches[record.employeeName] = employee;

      attendance.add(
        AttendanceRecord(
          employeeName: employee.name,
          employeeEmail: employee.email,
          date: record.date,
          status: status,
        ),
      );
    }

    return (records: attendance, unmatchedNames: unmatched.toList()..sort());
  }

  ({List<AttendanceRecord> records, List<String> unmatchedNames})
  buildRecordsFromLoginHours({
    required List<LoginHoursRecord> loginHours,
    required List<Employee> employees,
    DateTime? today,
  }) {
    final matches = <String, PortalEmployeeMatch>{};
    final unmatched = <String>{};
    final attendance = <AttendanceRecord>[];

    // Group by biometric identity so merge can recompute status per person.
    final byEmployee = <String, List<LoginHoursRecord>>{};
    for (final record in loginHours) {
      byEmployee.putIfAbsent(record.employeeName, () => []).add(record);
    }

    for (final entry in byEmployee.entries) {
      final employee =
          matches[entry.key] ?? matcher.find(entry.key, employees);
      if (employee == null) {
        unmatched.add(entry.key);
        continue;
      }
      matches[entry.key] = employee;

      final merged = mergeService.merge(
        employeeName: employee.name,
        employeeEmail: employee.email,
        stored: const [],
        loginHours: entry.value,
        today: today,
      );

      for (final record in merged) {
        final status = record.status.toUpperCase();
        if (!AttendanceStatus.calendarSyncStatuses.contains(status)) {
          continue;
        }
        attendance.add(
          AttendanceRecord(
            employeeName: employee.name,
            employeeEmail: employee.email,
            date: record.date,
            status: status,
          ),
        );
      }
    }

    return (records: attendance, unmatchedNames: unmatched.toList()..sort());
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/repositories/attendance_repository.dart';
import 'package:hr_portal/repositories/employee_repository.dart';
import 'package:hr_portal/services/biometric_calendar_sync_service.dart';

class _FakeEmployeeRepository implements EmployeeRepository {
  _FakeEmployeeRepository(this.employees);

  final List<Employee> employees;

  @override
  Future<List<Employee>> getAllEmployees() async => employees;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _RecordingAttendanceRepository implements AttendanceRepository {
  List<AttendanceRecord> synced = const [];

  @override
  Future<int> importBiometricAttendanceRecords(
    List<AttendanceRecord> records,
  ) async {
    synced = records;
    return records.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  final date = DateTime(2026, 6, 1);

  BiometricDailyAttendance record({
    required String name,
    required String status,
    String? firstIn,
  }) {
    return BiometricDailyAttendance(
      employeeId: '001',
      employeeName: name,
      date: date,
      status: status,
      firstIn: firstIn,
    );
  }

  group('BiometricCalendarSyncService', () {
    test(
      'maps P and A days to attendance records with employee email',
      () async {
        final attendanceRepo = _RecordingAttendanceRepository();
        final service = BiometricCalendarSyncService(
          employeeRepository: _FakeEmployeeRepository([
            const Employee(
              email: 'Ritu.Sharma@caglobal.com',
              name: 'Ritu Sharma',
              openingBalance: 0,
            ),
          ]),
          attendanceRepository: attendanceRepo,
        );

        final result = await service.sync([
          record(name: 'Ritu', status: 'P', firstIn: '11:07'),
          record(name: 'Ritu', status: 'A'),
        ]);

        expect(result.syncedCount, 2);
        expect(result.unmatchedNames, isEmpty);
        expect(attendanceRepo.synced.first.employeeName, 'Ritu Sharma');
        expect(
          attendanceRepo.synced.first.employeeEmail,
          'ritu.sharma@caglobal.com',
        );
        expect(attendanceRepo.synced.map((r) => r.status), ['P', 'A']);
      },
    );

    test('skips weekoff days', () async {
      final attendanceRepo = _RecordingAttendanceRepository();
      final service = BiometricCalendarSyncService(
        employeeRepository: _FakeEmployeeRepository([
          const Employee(
            email: 'ritu@caglobal.com',
            name: 'Ritu',
            openingBalance: 0,
          ),
        ]),
        attendanceRepository: attendanceRepo,
      );

      await service.sync([record(name: 'Ritu', status: 'weekoff')]);

      expect(attendanceRepo.synced, isEmpty);
    });

    test('reports biometric names without a portal account', () async {
      final attendanceRepo = _RecordingAttendanceRepository();
      final service = BiometricCalendarSyncService(
        employeeRepository: _FakeEmployeeRepository(const []),
        attendanceRepository: attendanceRepo,
      );

      final result = await service.sync([record(name: 'Nobody', status: 'A')]);

      expect(result.syncedCount, 0);
      expect(result.unmatchedNames, ['Nobody']);
    });

    test(
      'does not guess when a first name matches several employees',
      () async {
        final attendanceRepo = _RecordingAttendanceRepository();
        final service = BiometricCalendarSyncService(
          employeeRepository: _FakeEmployeeRepository([
            const Employee(
              email: 'rohit.a@caglobal.com',
              name: 'Rohit Ahuja',
              openingBalance: 0,
            ),
            const Employee(
              email: 'rohit.s@caglobal.com',
              name: 'Rohit Saini',
              openingBalance: 0,
            ),
          ]),
          attendanceRepository: attendanceRepo,
        );

        final result = await service.sync([record(name: 'Rohit', status: 'P')]);

        expect(result.unmatchedNames, ['Rohit']);
        expect(attendanceRepo.synced, isEmpty);
      },
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/services/login_hours_merge_service.dart';

void main() {
  const service = LoginHoursMergeService();
  final date = DateTime(2026, 6, 29);

  test('returns empty when no stored records for date', () {
    expect(service.mergeForDate(date: date, stored: const []), isEmpty);
  });

  test('includes full roster when only some employees are stored', () {
    final stored = [
      LoginHoursRecord(
        employeeId: '001',
        employeeName: 'Ritu',
        date: date,
        status: 'P',
        firstIn: '09:00',
      ),
    ];

    final merged = service.mergeForDate(date: date, stored: stored);

    expect(merged.length, BiometricEmployeeRoster.employees.length);
    expect(merged.first.employeeId, '001');
    expect(merged.first.firstIn, '09:00');
    expect(merged[1].employeeId, '002');
    expect(merged[1].firstIn, isNull);
  });
}

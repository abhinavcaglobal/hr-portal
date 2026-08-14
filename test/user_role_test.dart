import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/models/user_role.dart';

void main() {
  test('admin email resolves to admin role', () {
    expect('hr-india@caglobal.com'.toUserRole(), UserRole.admin);
  });

  test('employee email resolves to employee role', () {
    expect('employee@caglobal.com'.toUserRole(), UserRole.employee);
  });
}

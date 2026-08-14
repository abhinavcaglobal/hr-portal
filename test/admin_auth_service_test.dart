import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/services/admin_auth_service.dart';

void main() {
  const service = AdminAuthService();

  test('accepts valid admin credentials', () {
    expect(
      service.validateCredentials(
        email: 'hr-india@caglobal.com',
        password: 'Caglobal@1234',
      ),
      isTrue,
    );
  });

  test('accepts admin email case-insensitively', () {
    expect(
      service.validateCredentials(
        email: 'HR-India@CAGlobal.com',
        password: 'Caglobal@1234',
      ),
      isTrue,
    );
  });

  test('rejects invalid password', () {
    expect(
      service.validateCredentials(
        email: 'hr-india@caglobal.com',
        password: 'wrong-password',
      ),
      isFalse,
    );
  });

  test('rejects invalid email', () {
    expect(
      service.validateCredentials(
        email: 'other@caglobal.com',
        password: 'Caglobal@1234',
      ),
      isFalse,
    );
  });
}

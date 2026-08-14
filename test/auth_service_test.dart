import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('allows caglobal.com emails', () {
      expect(
        AuthService.isAllowedCompanyEmail('mayur.kumar@caglobal.com'),
        isTrue,
      );
      expect(
        AuthService.isAllowedCompanyEmail('HR-India@CAGlobal.com'),
        isTrue,
      );
    });

    test('rejects non-company emails', () {
      expect(AuthService.isAllowedCompanyEmail('user@gmail.com'), isFalse);
      expect(AuthService.isAllowedCompanyEmail('user@other.com'), isFalse);
      expect(AuthService.isAllowedCompanyEmail(''), isFalse);
    });
  });
}

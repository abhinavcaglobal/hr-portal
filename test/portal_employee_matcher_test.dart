import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/services/portal_employee_matcher.dart';

void main() {
  const matcher = PortalEmployeeMatcher();

  group('PortalEmployeeMatcher', () {
    test('matches short biometric name to full portal employee with email', () {
      final match = matcher.find('Ritu', [
        const Employee(
          email: 'Ritu.Sharma@caglobal.com',
          name: 'Ritu Sharma',
          openingBalance: 0,
        ),
      ]);

      expect(match?.name, 'Ritu Sharma');
      expect(match?.email, 'ritu.sharma@caglobal.com');
    });

    test('matches Rajeev to Rajiv Kumar even with no Firebase employee', () {
      final match = matcher.find('Rajeev', const []);

      expect(match?.name, 'Rajiv Kumar');
      expect(match?.email, isEmpty);
    });

    test('matches Rajeev when portal employee has empty email', () {
      final match = matcher.find('Rajeev', [
        const Employee(
          email: '',
          name: 'Rajiv Kumar',
          openingBalance: 0,
        ),
      ]);

      expect(match?.name, 'Rajiv Kumar');
      expect(match?.email, isEmpty);
    });

    test('returns null for unknown biometric names', () {
      expect(matcher.find('Nobody', const []), isNull);
    });
  });
}

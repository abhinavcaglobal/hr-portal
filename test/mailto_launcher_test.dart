import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/utils/mailto_launcher.dart';

void main() {
  group('isValidEmployeeEmail', () {
    test('accepts a standard work email', () {
      expect(isValidEmployeeEmail('john@company.com'), isTrue);
    });

    test('rejects empty or missing values', () {
      expect(isValidEmployeeEmail(null), isFalse);
      expect(isValidEmployeeEmail(''), isFalse);
      expect(isValidEmployeeEmail('   '), isFalse);
    });

    test('rejects values without a domain', () {
      expect(isValidEmployeeEmail('john@'), isFalse);
      expect(isValidEmployeeEmail('not-an-email'), isFalse);
    });
  });

  group('mailtoUriFor', () {
    test('builds a mailto URI with only the To address', () {
      final uri = mailtoUriFor('john@company.com');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'mailto');
      expect(uri.path, 'john@company.com');
      expect(uri.query, isEmpty);
      expect(uri.queryParameters.containsKey('subject'), isFalse);
      expect(uri.queryParameters.containsKey('body'), isFalse);
    });

    test('returns null for an invalid email', () {
      expect(mailtoUriFor(''), isNull);
      expect(mailtoUriFor('missing-at-sign'), isNull);
    });
  });
}

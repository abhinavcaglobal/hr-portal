import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/services/login_hours_status_resolver.dart';

void main() {
  const resolver = LoginHoursStatusResolver();

  group('LoginHoursStatusResolver', () {
    test('recalculates present when late punch window is corrected', () {
      final status = resolver.resolve(
        firstIn: '12:08',
        lastOut: '20:15',
        statusInput: 'SL',
      );

      expect(status, 'P');
    });

    test('marks late punch for 12:12 arrival with full duration', () {
      final status = resolver.resolve(
        firstIn: '12:12',
        lastOut: '20:15',
        statusInput: 'P',
      );

      expect(status, 'LP');
    });

    test('preserves explicit leave status', () {
      final status = resolver.resolve(
        firstIn: '09:00',
        lastOut: '18:00',
        statusInput: 'L',
      );

      expect(status, 'L');
    });

    test('preserves weekoff', () {
      final status = resolver.resolve(
        firstIn: '',
        lastOut: '',
        statusInput: 'weekoff',
      );

      expect(status, 'weekoff');
    });
  });
}

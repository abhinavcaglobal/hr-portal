import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/constants/employee_list.dart';

void main() {
  group('EmployeeList.filter', () {
    test('returns all names when query is empty', () {
      expect(EmployeeList.filter(''), EmployeeList.names);
    });

    test('filters by partial name case-insensitively', () {
      final result = EmployeeList.filter('kumar');
      expect(result, contains('Mayur Kumar'));
      expect(result, contains('Nitesh Kumar'));
      expect(result, isNot(contains('Anjali')));
    });

    test('returns empty list when no match', () {
      expect(EmployeeList.filter('zzzzz'), isEmpty);
    });
  });
}

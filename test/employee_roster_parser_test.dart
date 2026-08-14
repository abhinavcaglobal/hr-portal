import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/services/employee_roster_parser.dart';

void main() {
  const parser = EmployeeRosterParser();

  test('parses name, email, and openingBalance columns', () {
    final employees = parser.parse([
      ['name', 'email', 'openingBalance'],
      ['Mayur Kumar', 'mayur.kumar@caglobal.com', '5'],
      ['Priya Sharma', 'priya.sharma@caglobal.com', '3'],
    ]);

    expect(employees.length, 2);
    expect(employees.first.name, 'Mayur Kumar');
    expect(employees.first.email, 'mayur.kumar@caglobal.com');
    expect(employees.first.openingBalance, 5);
  });

  test('defaults openingBalance to zero when column is missing', () {
    final employees = parser.parse([
      ['name', 'email'],
      ['Mayur Kumar', 'mayur.kumar@caglobal.com'],
    ]);

    expect(employees.single.openingBalance, 0);
  });

  test('rejects invalid headers', () {
    expect(
      () => parser.parse([
        ['name', 'openingBalance'],
        ['Mayur Kumar', '5'],
      ]),
      throwsA(isA<DataException>()),
    );
  });

  test('rejects duplicate emails', () {
    expect(
      () => parser.parse([
        ['name', 'email'],
        ['A', 'same@caglobal.com'],
        ['B', 'same@caglobal.com'],
      ]),
      throwsA(isA<DataException>()),
    );
  });

  test('rejects non-company emails', () {
    expect(
      () => parser.parse([
        ['name', 'email'],
        ['A', 'a@gmail.com'],
      ]),
      throwsA(isA<DataException>()),
    );
  });
}

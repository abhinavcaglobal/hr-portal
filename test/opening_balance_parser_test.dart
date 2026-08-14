import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/services/opening_balance_parser.dart';

void main() {
  const parser = OpeningBalanceParser();

  test('parses name and openingBalance columns', () {
    final employees = parser.parse([
      ['name', 'openingBalance'],
      ['Mayur Kumar', '5'],
      ['Sukhwinder Kaur', '3'],
    ]);

    expect(employees.length, 2);
    expect(employees.first.name, 'Mayur Kumar');
    expect(employees.first.openingBalance, 5);
    expect(employees.first.email, '');
  });

  test('parses optional email column', () {
    final employees = parser.parse([
      ['name', 'openingBalance', 'email'],
      ['Mayur Kumar', '5', 'mayur.kumar@caglobal.com'],
    ]);

    expect(employees.single.email, 'mayur.kumar@caglobal.com');
  });
}

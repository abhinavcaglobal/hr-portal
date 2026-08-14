import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/employee.dart';

class OpeningBalanceParser {
  const OpeningBalanceParser();

  List<Employee> parse(List<List<String>> rows) {
    if (rows.isEmpty) {
      throw const DataException('Opening balance file is empty.');
    }

    final header = rows.first.map((c) => c.trim().toLowerCase()).toList();
    final nameIndex = header.indexOf('name');
    final balanceIndex = header.indexOf('openingbalance');
    final emailIndex = header.indexOf('email');

    if (nameIndex == -1 || balanceIndex == -1) {
      throw const DataException(
        'Invalid headers. Row 1 must contain: name, openingBalance',
      );
    }

    final employees = <Employee>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= nameIndex) continue;

      final name = row[nameIndex].trim();
      if (name.isEmpty) continue;

      final balanceText = balanceIndex < row.length
          ? row[balanceIndex].trim()
          : '0';
      final balance = double.tryParse(balanceText) ?? 0;
      final email = emailIndex != -1 && emailIndex < row.length
          ? row[emailIndex].trim().toLowerCase()
          : '';

      employees.add(
        Employee(name: name, email: email, openingBalance: balance),
      );
    }

    if (employees.isEmpty) {
      throw const DataException(
        'No employee rows found in opening balance file.',
      );
    }

    return employees;
  }
}

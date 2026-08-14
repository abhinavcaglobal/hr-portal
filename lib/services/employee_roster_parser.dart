import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/employee.dart';

class EmployeeRosterParser {
  const EmployeeRosterParser();

  List<Employee> parse(List<List<String>> rows) {
    if (rows.isEmpty) {
      throw const DataException('Employee roster file is empty.');
    }

    final header = rows.first.map((c) => c.trim().toLowerCase()).toList();
    final nameIndex = header.indexOf('name');
    final emailIndex = header.indexOf('email');
    final balanceIndex = header.indexOf('openingbalance');

    if (nameIndex == -1 || emailIndex == -1) {
      throw const DataException(
        'Invalid headers. Row 1 must contain: name, email',
      );
    }

    final employees = <Employee>[];
    final seenEmails = <String>{};

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= nameIndex) continue;

      final name = row[nameIndex].trim();
      final email = emailIndex < row.length ? row[emailIndex].trim() : '';
      if (name.isEmpty || email.isEmpty) continue;

      final normalizedEmail = email.toLowerCase();
      if (!normalizedEmail.endsWith(AppConstants.allowedEmailDomain)) {
        throw DataException(
          'Invalid email for $name. Use ${AppConstants.allowedEmailDomain} addresses.',
        );
      }

      if (seenEmails.contains(normalizedEmail)) {
        throw DataException('Duplicate email in roster: $email');
      }
      seenEmails.add(normalizedEmail);

      final balanceText = balanceIndex != -1 && balanceIndex < row.length
          ? row[balanceIndex].trim()
          : '0';
      final balance = double.tryParse(balanceText) ?? 0;

      employees.add(
        Employee(name: name, email: normalizedEmail, openingBalance: balance),
      );
    }

    if (employees.isEmpty) {
      throw const DataException('No employee rows found in roster file.');
    }

    return employees;
  }
}

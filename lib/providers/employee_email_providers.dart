import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/providers/repository_providers.dart';

final allEmployeesProvider = FutureProvider<List<Employee>>((ref) async {
  final employees = await ref
      .read(employeeRepositoryProvider)
      .getAllEmployees();
  final sorted = [...employees]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return sorted;
});

import 'package:hr_portal/core/constants/biometric_employee_roster.dart';
import 'package:hr_portal/core/constants/employee_list.dart';
import 'package:hr_portal/models/employee.dart';

/// Resolved portal identity used when writing attendance docs.
class PortalEmployeeMatch {
  const PortalEmployeeMatch({required this.name, this.email = ''});

  final String name;
  final String email;
}

/// Maps biometric / short names onto portal employees.
///
/// Email is preferred when present, but staff without an email (e.g. office
/// boy Rajiv Kumar) still resolve via [EmployeeList] + biometric roster aliases.
class PortalEmployeeMatcher {
  const PortalEmployeeMatcher();

  PortalEmployeeMatch? find(
    String biometricName,
    List<Employee> employees,
  ) {
    final target = _normalize(_stripWfhLabel(biometricName));
    if (target.isEmpty) return null;

    final candidates = _candidateEmployees(target, employees);
    if (candidates.length > 1) {
      return null;
    }
    if (candidates.length == 1) {
      final employee = candidates.first;
      return PortalEmployeeMatch(
        name: employee.name,
        email: employee.email.trim().toLowerCase(),
      );
    }

    final portalName = _portalNameFromRoster(target);
    if (portalName == null) return null;

    final email = _emailForPortalName(portalName, employees);
    return PortalEmployeeMatch(name: portalName, email: email);
  }

  List<Employee> _candidateEmployees(String target, List<Employee> employees) {
    if (employees.isEmpty) return const [];

    final ranked = [
      ...employees.where((e) => e.email.trim().isNotEmpty),
      ...employees.where((e) => e.email.trim().isEmpty),
    ];

    final matches = <Employee>[];
    for (final employee in ranked) {
      final name = _normalize(_stripWfhLabel(employee.name));
      if (name == target || name.startsWith('$target ')) {
        matches.add(employee);
        continue;
      }

      final biometric = BiometricEmployeeRoster.findByEmployeeName(
        employee.name,
      );
      if (biometric == null) continue;
      if (_normalize(biometric.name) == target ||
          _normalize(biometric.displayName) == target) {
        matches.add(employee);
      }
    }
    return matches;
  }

  String? _portalNameFromRoster(String target) {
    BiometricEmployee? biometric;
    for (final entry in BiometricEmployeeRoster.employees) {
      if (_normalize(entry.name) == target ||
          _normalize(entry.displayName) == target) {
        biometric = entry;
        break;
      }
    }
    biometric ??= BiometricEmployeeRoster.findByEmployeeName(target);
    if (biometric == null) return null;

    for (final name in EmployeeList.names) {
      final match = BiometricEmployeeRoster.findByEmployeeName(name);
      if (match?.normalizedId == biometric.normalizedId) {
        return name;
      }
    }
    return biometric.displayName;
  }

  String _emailForPortalName(String portalName, List<Employee> employees) {
    final target = _normalize(_stripWfhLabel(portalName));
    for (final employee in employees) {
      if (_normalize(_stripWfhLabel(employee.name)) == target) {
        return employee.email.trim().toLowerCase();
      }
    }
    return '';
  }

  String _stripWfhLabel(String name) {
    final trimmed = name.trim();
    final match = RegExp(
      r'^(.*?)\s*\(\s*wfh\s*\)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    return match?.group(1)?.trim() ?? trimmed;
  }

  String _normalize(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

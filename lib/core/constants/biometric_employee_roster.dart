class BiometricEmployee {
  const BiometricEmployee({
    required this.id,
    required this.name,
    this.isWfh = false,
  });

  final String id;
  final String name;
  final bool isWfh;

  String get normalizedId => id.padLeft(3, '0');

  /// Name shown in Login Hours / biometric results (e.g. "Simran (WFH)").
  String get displayName => isWfh ? '$name (WFH)' : name;
}

/// Biometric machine employee roster (name + ID from attendance device).
class BiometricEmployeeRoster {
  BiometricEmployeeRoster._();

  static const List<BiometricEmployee> employees = [
    BiometricEmployee(id: '001', name: 'Ritu'),
    BiometricEmployee(id: '002', name: 'Akanksha'),
    BiometricEmployee(id: '003', name: 'chhavi'),
    BiometricEmployee(id: '004', name: 'Sukhwinder'),
    BiometricEmployee(id: '005', name: 'Amritpal'),
    BiometricEmployee(id: '006', name: 'Vikas'),
    BiometricEmployee(id: '008', name: 'Rishu'),
    BiometricEmployee(id: '010', name: 'Simarjeet'),
    BiometricEmployee(id: '011', name: 'Sonia'),
    BiometricEmployee(id: '013', name: 'Sahil'),
    BiometricEmployee(id: '014', name: 'Sarprinder'),
    BiometricEmployee(id: '015', name: 'Abhinav'),
    BiometricEmployee(id: '016', name: 'Nitesh'),
    BiometricEmployee(id: '017', name: 'Narad'),
    BiometricEmployee(id: '018', name: 'Anjali'),
    BiometricEmployee(id: '019', name: 'Poonam'),
    BiometricEmployee(id: '020', name: 'Pooja'),
    BiometricEmployee(id: '022', name: 'Shobhit'),
    BiometricEmployee(id: '023', name: 'Anmol'),
    BiometricEmployee(id: '024', name: 'Smarpit'),
    BiometricEmployee(id: '026', name: 'Nikita'),
    BiometricEmployee(id: '027', name: 'Sakshi'),
    BiometricEmployee(id: '028', name: 'Ravneet'),
    BiometricEmployee(id: '030', name: 'Vineet'),
    BiometricEmployee(id: '031', name: 'Pratima'),
    BiometricEmployee(id: '032', name: 'Jaichand'),
    BiometricEmployee(id: '033', name: 'Anshul'),
    BiometricEmployee(id: '034', name: 'Ashima'),
    BiometricEmployee(id: '036', name: 'Vikram'),
    BiometricEmployee(id: '037', name: 'Kulbhushan'),
    BiometricEmployee(id: '038', name: 'Tanuj'),
    BiometricEmployee(id: '039', name: 'Sachin'),
    BiometricEmployee(id: '040', name: 'Vivek'),
    BiometricEmployee(id: '041', name: 'Jatinder'),
    BiometricEmployee(id: '042', name: 'Sourav'),
    BiometricEmployee(id: '043', name: 'Manisha'),
    BiometricEmployee(id: '044', name: 'Isha'),
    BiometricEmployee(id: '045', name: 'Raju'),
    BiometricEmployee(id: '046', name: 'Armaan'),
    BiometricEmployee(id: '048', name: 'Yashpal'),
    BiometricEmployee(id: '051', name: 'Mayur'),
    BiometricEmployee(id: '052', name: 'Gurpreet'),
    BiometricEmployee(id: '054', name: 'Rajeev'),
    BiometricEmployee(id: '056', name: 'Arvind'),
    BiometricEmployee(id: '057', name: 'Kajal'),
    BiometricEmployee(id: '058', name: 'Sameer'),
    BiometricEmployee(id: '059', name: 'Ketan'),
    BiometricEmployee(id: '060', name: 'Rohit'),
    BiometricEmployee(id: '062', name: 'Abhay'),
    BiometricEmployee(id: '064', name: 'Simran', isWfh: true),
    BiometricEmployee(id: '065', name: 'Rohit Saini'),
    BiometricEmployee(id: '066', name: 'Sanjeev Kumar'),
    BiometricEmployee(id: '069', name: 'Kawaldeep Kaur'),
    BiometricEmployee(id: '070', name: 'Pankaj kalsi'),
  ];

  static BiometricEmployee? findById(String id) {
    final normalized = id.padLeft(3, '0');
    for (final employee in employees) {
      if (employee.normalizedId == normalized) {
        return employee;
      }
    }
    return null;
  }

  /// Resolves a portal employee name (often a full name such as
  /// "Ritu Sharma") to its biometric roster entry, which usually stores only
  /// the first name. Returns null when the match would be ambiguous.
  static BiometricEmployee? findByEmployeeName(String name) {
    final target = _normalize(_stripWfhLabel(name));
    if (target.isEmpty) return null;

    for (final employee in employees) {
      if (_normalize(employee.name) == target) {
        return employee;
      }
    }

    final prefixMatches = employees
        .where((employee) => target.startsWith('${_normalize(employee.name)} '))
        .toList();

    return prefixMatches.length == 1 ? prefixMatches.first : null;
  }

  static bool isWfhEmployee(String employeeIdOrName) {
    final byId = findById(employeeIdOrName);
    if (byId != null) return byId.isWfh;

    final byName = findByEmployeeName(employeeIdOrName);
    return byName?.isWfh ?? false;
  }

  static String _stripWfhLabel(String name) {
    final trimmed = name.trim();
    final match = RegExp(
      r'^(.*?)\s*\(\s*wfh\s*\)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    return match?.group(1)?.trim() ?? trimmed;
  }

  static String _normalize(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

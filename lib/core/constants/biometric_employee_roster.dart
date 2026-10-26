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
    BiometricEmployee(id: '028', name: 'Shouvik Dey'),
    BiometricEmployee(id: '030', name: 'Vineet'),
    BiometricEmployee(id: '031', name: 'Pratima'),
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
    BiometricEmployee(id: '071', name: 'Rahul'),
    BiometricEmployee(id: '072', name: 'Nikhil'),
    BiometricEmployee(id: '073', name: 'Amanjot'),
    BiometricEmployee(id: '074', name: 'Baby Jangra'),
  ];

  /// Order used on the biometric results screen and in Excel/CSV downloads.
  /// Names match [BiometricEmployee.displayName]. People not listed here are
  /// appended after this sequence, ordered by device ID.
  static const List<String> reportOrder = [
    'Mayur',
    'Sukhwinder',
    'Amritpal',
    'Vikas',
    'Rishu',
    'Simarjeet',
    'Ritu',
    'Sonia',
    'Sahil',
    'Sarprinder',
    'Abhinav',
    'Nitesh',
    'Narad',
    'Anjali',
    'Poonam',
    'Pooja',
    'Shobhit',
    'Anmol',
    'Smarpit',
    'Nikita',
    'Sakshi',
    'Vineet',
    'Pratima',
    'Anshul',
    'Ashima',
    'Vikram',
    'Kulbhushan',
    'Tanuj',
    'Akanksha',
    'Sachin',
    'Vivek',
    'Jatinder',
    'Sourav',
    'Manisha',
    'Isha',
    'Raju',
    'Armaan',
    'Yashpal',
    'Gurpreet',
    'Rajeev',
    'Arvind',
    'Kajal',
    'Sameer',
    'Ketan',
    'Rohit',
    'Abhay',
    'Simran (WFH)',
    'Rohit Saini',
    'Sanjeev Kumar',
    'Kawaldeep Kaur',
    'Pankaj kalsi',
    'Rahul',
    'Nikhil',
    'Amanjot',
    'Baby Jangra',
    'Shouvik Dey',
  ];

  static final Map<String, int> _reportRankByName = {
    for (var index = 0; index < reportOrder.length; index++)
      _normalize(reportOrder[index]): index,
  };

  /// HR report order, then device ID for anyone not in [reportOrder].
  static int compareReportOrder({
    required String aName,
    required String aId,
    required String bName,
    required String bId,
  }) {
    final rankA = _reportRankByName[_normalize(aName)] ?? reportOrder.length;
    final rankB = _reportRankByName[_normalize(bName)] ?? reportOrder.length;
    final byRank = rankA.compareTo(rankB);
    if (byRank != 0) return byRank;

    final byId = aId.compareTo(bId);
    if (byId != 0) return byId;
    return _normalize(aName).compareTo(_normalize(bName));
  }

  /// Spelling differences between the biometric device and the portal roster.
  /// Keys are normalized biometric names; values are alternate portal forms.
  static const Map<String, List<String>> portalAliasesByBiometricName = {
    // Device: "Rajeev" (office boy) ↔ portal: "Rajiv Kumar"
    'rajeev': ['rajiv', 'rajiv kumar'],
  };

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
    if (prefixMatches.length == 1) return prefixMatches.first;
    if (prefixMatches.isNotEmpty) return null;

    // Compound first names: "Armaanpreet kaur" → biometric "Armaan".
    final firstWord = target.split(' ').first;
    final firstNameMatches = employees.where((employee) {
      final biometricName = _normalize(employee.name);
      if (biometricName.contains(' ')) return false;
      return firstWord.startsWith(biometricName);
    }).toList();
    if (firstNameMatches.length == 1) return firstNameMatches.first;
    if (firstNameMatches.isNotEmpty) return null;

    // Explicit aliases (e.g. Rajeev ↔ Rajiv Kumar).
    for (final employee in employees) {
      final aliases =
          portalAliasesByBiometricName[_normalize(employee.name)];
      if (aliases == null) continue;
      for (final alias in aliases) {
        if (target == alias || target.startsWith('$alias ')) {
          return employee;
        }
      }
    }

    return null;
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

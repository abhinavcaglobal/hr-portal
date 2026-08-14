class Employee {
  const Employee({
    required this.email,
    required this.name,
    required this.openingBalance,
  });

  final String email;
  final String name;
  final double openingBalance;

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      openingBalance: _toDouble(map['openingBalance']),
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'openingBalance': openingBalance,
  };

  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Employee copyWith({String? email, String? name, double? openingBalance}) {
    return Employee(
      email: email ?? this.email,
      name: name ?? this.name,
      openingBalance: openingBalance ?? this.openingBalance,
    );
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.employeeName,
    required this.date,
    required this.status,
    this.id,
    this.employeeEmail,
  });

  final String? id;
  final String employeeName;
  final String? employeeEmail;
  final DateTime date;
  final String status;

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    return AttendanceRecord(
      id: id,
      employeeName:
          map['employeeName'] as String? ??
          map['employeeEmail'] as String? ??
          '',
      employeeEmail: map['employeeEmail'] as String?,
      date: _parseDate(map['date']),
      status: (map['status'] as String? ?? '').toUpperCase(),
    );
  }

  Map<String, dynamic> toMap() => {
    'employeeName': employeeName,
    'employeeEmail': employeeEmail?.trim().toLowerCase() ?? '',
    'date': _formatDate(date),
    'status': status,
  };

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      final parts = value.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

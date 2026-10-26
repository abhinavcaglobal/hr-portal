class AttendanceMonthNote {
  const AttendanceMonthNote({
    required this.employeeName,
    required this.year,
    required this.month,
    this.id,
    this.employeeEmail,
    this.remarks = '',
    this.reference = '',
  });

  final String? id;
  final String employeeName;
  final String? employeeEmail;
  final int year;
  final int month;
  final String remarks;
  final String reference;

  factory AttendanceMonthNote.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    return AttendanceMonthNote(
      id: id,
      employeeName: map['employeeName'] as String? ?? '',
      employeeEmail: map['employeeEmail'] as String?,
      year: (map['year'] as num?)?.toInt() ?? 0,
      month: (map['month'] as num?)?.toInt() ?? 0,
      remarks: map['remarks'] as String? ?? '',
      reference: map['reference'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'employeeName': employeeName,
    'employeeEmail': employeeEmail?.trim().toLowerCase() ?? '',
    'year': year,
    'month': month,
    'remarks': remarks,
    'reference': reference,
  };

  AttendanceMonthNote copyWith({
    String? remarks,
    String? reference,
    String? employeeEmail,
  }) {
    return AttendanceMonthNote(
      id: id,
      employeeName: employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      year: year,
      month: month,
      remarks: remarks ?? this.remarks,
      reference: reference ?? this.reference,
    );
  }
}

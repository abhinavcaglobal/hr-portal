import 'package:hr_portal/models/biometric_attendance.dart';

class LoginHoursRecord {
  const LoginHoursRecord({
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.status,
    this.id,
    this.firstIn,
    this.lastOut,
    this.remarks = '',
    this.manuallyEdited = false,
  });

  final String? id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final String status;
  final String? firstIn;
  final String? lastOut;
  final String remarks;
  final bool manuallyEdited;

  bool get isLeave => status == 'L';
  bool get isWeekOff => status == 'weekoff';
  bool get isPresent => status == 'P';
  bool get isAbsent => status == 'A';
  bool get isWfh => status.toUpperCase() == 'WFH';

  bool get hasCompleteOut => lastOut != null && lastOut!.trim().isNotEmpty;

  factory LoginHoursRecord.fromBiometric(BiometricDailyAttendance record) {
    return LoginHoursRecord(
      employeeId: record.employeeId,
      employeeName: record.employeeName,
      date: record.date,
      status: record.status,
      firstIn: record.firstIn,
      lastOut: record.lastOut,
    );
  }

  factory LoginHoursRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    return LoginHoursRecord(
      id: id,
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      date: _parseDate(map['date']),
      status: map['status'] as String? ?? '',
      firstIn: map['firstIn'] as String?,
      lastOut: map['lastOut'] as String?,
      remarks: map['remarks'] as String? ?? '',
      manuallyEdited: map['manuallyEdited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'employeeId': employeeId,
    'employeeName': employeeName,
    'date': _formatDate(date),
    'status': status,
    if (firstIn != null && firstIn!.isNotEmpty) 'firstIn': firstIn,
    if (lastOut != null && lastOut!.isNotEmpty) 'lastOut': lastOut,
    'remarks': remarks,
    'manuallyEdited': manuallyEdited,
  };

  LoginHoursRecord copyWith({
    String? employeeId,
    String? employeeName,
    DateTime? date,
    String? status,
    String? firstIn,
    String? lastOut,
    String? remarks,
    bool? manuallyEdited,
    bool clearFirstIn = false,
    bool clearLastOut = false,
  }) {
    return LoginHoursRecord(
      id: id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      status: status ?? this.status,
      firstIn: clearFirstIn ? null : (firstIn ?? this.firstIn),
      lastOut: clearLastOut ? null : (lastOut ?? this.lastOut),
      remarks: remarks ?? this.remarks,
      manuallyEdited: manuallyEdited ?? this.manuallyEdited,
    );
  }

  String get recordKey => '${employeeId}_${_formatDate(date)}';

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

enum LoginHoursSyncAction { create, updateOutOnly, correctSpan, skip }

class LoginHoursSyncDecision {
  const LoginHoursSyncDecision({required this.action, this.record});

  final LoginHoursSyncAction action;
  final LoginHoursRecord? record;

  bool get shouldWrite =>
      action == LoginHoursSyncAction.create ||
      action == LoginHoursSyncAction.updateOutOnly ||
      action == LoginHoursSyncAction.correctSpan;
}

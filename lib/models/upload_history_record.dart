import 'package:cloud_firestore/cloud_firestore.dart';

class UploadHistoryRecord {
  const UploadHistoryRecord({
    required this.id,
    required this.fileName,
    required this.uploadType,
    required this.uploadedAt,
    required this.uploadedBy,
    this.status = 'pending',
  });

  final String id;
  final String fileName;
  final String uploadType;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String status;

  factory UploadHistoryRecord.fromMap(Map<String, dynamic> map, String id) {
    return UploadHistoryRecord(
      id: id,
      fileName: map['fileName'] as String? ?? '',
      uploadType: map['uploadType'] as String? ?? '',
      uploadedAt: _parseDateTime(map['uploadedAt']),
      uploadedBy: map['uploadedBy'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value != null) {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

enum UploadType {
  openingBalance('opening_balance'),
  employeeRoster('employee_roster'),
  attendance('attendance');

  const UploadType(this.value);
  final String value;

  String get label => switch (this) {
    UploadType.openingBalance => 'Opening Balance',
    UploadType.employeeRoster => 'Employee Roster',
    UploadType.attendance => 'Attendance',
  };
}

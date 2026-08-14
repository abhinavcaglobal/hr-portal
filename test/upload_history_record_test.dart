import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/models/upload_history_record.dart';

void main() {
  test('parses Firestore Timestamp for uploadedAt', () {
    final uploadedAt = DateTime(2026, 6, 15, 14, 30);
    final record = UploadHistoryRecord.fromMap({
      'fileName': 'Attendance - June.csv',
      'uploadType': 'attendance',
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': 'hr-india@caglobal.com',
      'status': 'imported',
    }, 'doc-1');

    expect(record.uploadedAt, uploadedAt);
  });

  test('does not use current time when timestamp is missing', () {
    final before = DateTime.now();
    final record = UploadHistoryRecord.fromMap({
      'fileName': 'test.xlsx',
      'uploadType': 'employee_roster',
      'uploadedBy': 'hr-india@caglobal.com',
    }, 'doc-2');
    final after = DateTime.now();

    expect(record.uploadedAt.isBefore(before), isTrue);
    expect(record.uploadedAt.isAfter(after), isFalse);
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/models/holiday_calendar_document.dart';

void main() {
  test('parses holiday calendar metadata', () {
    final uploadedAt = DateTime(2026, 8, 12, 18, 30);
    final calendar = HolidayCalendarDocument.fromMap({
      'fileName': 'India Team Holiday Calendar_2026.pdf',
      'downloadUrl': 'https://example.com/calendar.pdf',
      'storagePath': 'holiday_calendars/2026/calendar.pdf',
      'year': 2026,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': 'hr-india@caglobal.com',
    });

    expect(calendar.fileName, 'India Team Holiday Calendar_2026.pdf');
    expect(calendar.year, 2026);
    expect(calendar.uploadedAt, uploadedAt);
  });

  test('uses epoch when upload timestamp is pending', () {
    final calendar = HolidayCalendarDocument.fromMap({
      'fileName': 'calendar.pdf',
      'downloadUrl': 'https://example.com/calendar.pdf',
      'storagePath': 'holiday_calendars/2026/calendar.pdf',
      'year': 2026,
      'uploadedBy': 'hr-india@caglobal.com',
    });

    expect(calendar.uploadedAt.millisecondsSinceEpoch, 0);
  });
}

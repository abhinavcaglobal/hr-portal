import 'package:cloud_firestore/cloud_firestore.dart';

class HolidayCalendarDocument {
  const HolidayCalendarDocument({
    required this.fileName,
    required this.downloadUrl,
    required this.storagePath,
    required this.year,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  final String fileName;
  final String downloadUrl;
  final String storagePath;
  final int year;
  final DateTime uploadedAt;
  final String uploadedBy;

  factory HolidayCalendarDocument.fromMap(Map<String, dynamic> map) {
    return HolidayCalendarDocument(
      fileName: map['fileName'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? '',
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      uploadedAt: _parseDateTime(map['uploadedAt']),
      uploadedBy: map['uploadedBy'] as String? ?? '',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/attendance_month_note.dart';
import 'package:hr_portal/services/firebase_service.dart';

abstract class AttendanceMonthNotesRepository {
  Future<List<AttendanceMonthNote>> getNotesForMonth({
    required int year,
    required int month,
  });

  Future<void> upsertNote(AttendanceMonthNote note);
}

class AttendanceMonthNotesRepositoryImpl
    implements AttendanceMonthNotesRepository {
  AttendanceMonthNotesRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseService.firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.attendanceMonthNotesCollection);

  @override
  Future<List<AttendanceMonthNote>> getNotesForMonth({
    required int year,
    required int month,
  }) async {
    try {
      final snapshot = await _collection
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceMonthNote.fromMap(doc.data(), id: doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load attendance notes.',
        code: e.code,
      );
    }
  }

  @override
  Future<void> upsertNote(AttendanceMonthNote note) async {
    try {
      final docId = _documentId(note.employeeName, note.year, note.month);
      await _collection.doc(docId).set(note.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to save attendance notes.',
        code: e.code,
      );
    }
  }

  String _documentId(String employeeName, int year, int month) {
    final monthKey = month.toString().padLeft(2, '0');
    return '${employeeName}_${year}_$monthKey'
        .replaceAll(' ', '_')
        .replaceAll('.', '_');
  }
}

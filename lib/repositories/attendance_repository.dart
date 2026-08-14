import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/services/firebase_service.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceForMonth({
    required String employeeEmail,
    required int year,
    required int month,
  });

  Future<List<AttendanceRecord>> getAllAttendanceForEmployeeEmail(
    String employeeEmail,
  );

  /// Admin / import only — queries by display name.
  Future<List<AttendanceRecord>> getAllAttendanceForEmployeeName(String name);

  Future<void> importAttendanceRecords(List<AttendanceRecord> records);

  /// Writes biometric P/A days, leaving manually marked leave days untouched.
  /// Returns the number of records written.
  Future<int> importBiometricAttendanceRecords(List<AttendanceRecord> records);
}

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseService.firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.attendanceCollection);

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  @override
  Future<List<AttendanceRecord>> getAttendanceForMonth({
    required String employeeEmail,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      final email = _normalizeEmail(employeeEmail);

      final snapshot = await _collection
          .where('employeeEmail', isEqualTo: email)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), id: doc.id))
          .where((r) => !r.date.isBefore(startDate) && !r.date.isAfter(endDate))
          .toList();
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load attendance.',
        code: e.code,
      );
    }
  }

  @override
  Future<List<AttendanceRecord>> getAllAttendanceForEmployeeEmail(
    String employeeEmail,
  ) async {
    try {
      final email = _normalizeEmail(employeeEmail);
      final snapshot = await _collection
          .where('employeeEmail', isEqualTo: email)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), id: doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load attendance records.',
        code: e.code,
      );
    }
  }

  @override
  Future<List<AttendanceRecord>> getAllAttendanceForEmployeeName(
    String name,
  ) async {
    try {
      final snapshot = await _collection
          .where('employeeName', isEqualTo: name)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), id: doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load attendance records.',
        code: e.code,
      );
    }
  }

  @override
  Future<void> importAttendanceRecords(List<AttendanceRecord> records) async {
    try {
      const batchLimit = 450;
      for (var i = 0; i < records.length; i += batchLimit) {
        final batch = _firestore.batch();
        final chunk = records.skip(i).take(batchLimit);

        for (final record in chunk) {
          final dateStr = record.toMap()['date']! as String;
          final docId = _documentId(record.employeeName, dateStr);
          final docRef = _collection.doc(docId);
          batch.set(docRef, record.toMap(), SetOptions(merge: true));
        }

        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to import attendance.',
        code: e.code,
      );
    }
  }

  @override
  Future<int> importBiometricAttendanceRecords(
    List<AttendanceRecord> records,
  ) async {
    if (records.isEmpty) return 0;

    try {
      final protectedDocIds = await _loadLeaveMarkedDocIds(records);
      final writable = records.where((record) {
        final dateStr = record.toMap()['date']! as String;
        return !protectedDocIds.contains(
          _documentId(record.employeeName, dateStr),
        );
      }).toList();

      const batchLimit = 450;
      for (var i = 0; i < writable.length; i += batchLimit) {
        final batch = _firestore.batch();
        final chunk = writable.skip(i).take(batchLimit);

        for (final record in chunk) {
          final dateStr = record.toMap()['date']! as String;
          final docRef = _collection.doc(
            _documentId(record.employeeName, dateStr),
          );
          batch.set(docRef, record.toMap(), SetOptions(merge: true));
        }

        await batch.commit();
      }

      return writable.length;
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to sync attendance calendar.',
        code: e.code,
      );
    }
  }

  Future<Set<String>> _loadLeaveMarkedDocIds(
    List<AttendanceRecord> records,
  ) async {
    final dates = records
        .map((record) => record.toMap()['date']! as String)
        .toSet();
    final protectedDocIds = <String>{};

    for (final date in dates) {
      final snapshot = await _collection.where('date', isEqualTo: date).get();
      for (final doc in snapshot.docs) {
        final status = (doc.data()['status'] as String? ?? '').toUpperCase();
        if (status == AttendanceStatus.leave ||
            status == AttendanceStatus.halfLeave ||
            status == AttendanceStatus.shortLeave) {
          protectedDocIds.add(doc.id);
        }
      }
    }

    return protectedDocIds;
  }

  String _documentId(String employeeName, String date) {
    return '${employeeName}_$date'.replaceAll(' ', '_').replaceAll('.', '_');
  }
}

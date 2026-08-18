import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/services/firebase_service.dart';
import 'package:hr_portal/services/login_hours_merge_service.dart';
import 'package:hr_portal/services/login_hours_sync_service.dart';

abstract class LoginHoursRepository {
  Future<List<LoginHoursRecord>> getRecordsForDate(DateTime date);

  /// Stored records for one employee within a month, without roster padding.
  Future<List<LoginHoursRecord>> getRecordsForEmployeeMonth({
    required String employeeId,
    required int year,
    required int month,
  });

  /// Stored records for one employee on one date, without roster padding.
  Future<List<LoginHoursRecord>> getRecordsForEmployeeDate({
    required String employeeId,
    required DateTime date,
  });

  /// Stored records for one employee between [start] and [end], inclusive.
  Future<List<LoginHoursRecord>> getRecordsForEmployeeRange({
    required String employeeId,
    required DateTime start,
    required DateTime end,
  });

  /// Stored records for all employees between [start] and [end], inclusive.
  /// Does not pad the biometric roster.
  Future<List<LoginHoursRecord>> getRecordsForDateRange({
    required DateTime start,
    required DateTime end,
  });

  Future<void> importFromBiometricRecords(
    List<BiometricDailyAttendance> records,
  );

  Future<void> updateManually({
    required LoginHoursRecord record,
    required String firstIn,
    required String lastOut,
    required String status,
    required String remarks,
  });
}

class LoginHoursRepositoryImpl implements LoginHoursRepository {
  LoginHoursRepositoryImpl({
    FirebaseFirestore? firestore,
    LoginHoursSyncService? syncService,
    LoginHoursMergeService? mergeService,
  }) : _firestore = firestore ?? FirebaseService.firestore,
       _syncService = syncService ?? const LoginHoursSyncService(),
       _mergeService = mergeService ?? const LoginHoursMergeService();

  final FirebaseFirestore _firestore;
  final LoginHoursSyncService _syncService;
  final LoginHoursMergeService _mergeService;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.loginHoursCollection);

  @override
  Future<List<LoginHoursRecord>> getRecordsForDate(DateTime date) async {
    try {
      final dateStr = _formatDate(date);
      final snapshot = await _collection
          .where('date', isEqualTo: dateStr)
          .get();

      final records = snapshot.docs
          .map((doc) => LoginHoursRecord.fromMap(doc.data(), id: doc.id))
          .toList();

      return _mergeService.mergeForDate(date: date, stored: records);
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load login hours.',
        code: e.code,
      );
    }
  }

  @override
  Future<List<LoginHoursRecord>> getRecordsForEmployeeMonth({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    try {
      final snapshot = await _collection
          .where('employeeId', isEqualTo: employeeId)
          .get();

      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0);

      return snapshot.docs
          .map((doc) => LoginHoursRecord.fromMap(doc.data(), id: doc.id))
          .where(
            (record) =>
                !record.date.isBefore(monthStart) &&
                !record.date.isAfter(monthEnd),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load login hours.',
        code: e.code,
      );
    }
  }

  @override
  Future<List<LoginHoursRecord>> getRecordsForEmployeeDate({
    required String employeeId,
    required DateTime date,
  }) {
    return getRecordsForEmployeeRange(
      employeeId: employeeId,
      start: date,
      end: date,
    );
  }

  @override
  Future<List<LoginHoursRecord>> getRecordsForEmployeeRange({
    required String employeeId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _collection
          .where('employeeId', isEqualTo: employeeId)
          .get();
      return _filterAndSort(snapshot.docs, start: start, end: end);
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load login hours.',
        code: e.code,
      );
    }
  }

  @override
  Future<List<LoginHoursRecord>> getRecordsForDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = _formatDate(DateTime(start.year, start.month, start.day));
      final endStr = _formatDate(DateTime(end.year, end.month, end.day));
      final snapshot = await _collection
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .get();

      final records = snapshot.docs
          .map((doc) => LoginHoursRecord.fromMap(doc.data(), id: doc.id))
          .toList();
      records.sort(_byDateThenName);
      return records;
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load login hours.',
        code: e.code,
      );
    }
  }

  List<LoginHoursRecord> _filterAndSort(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required DateTime start,
    required DateTime end,
  }) {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(end.year, end.month, end.day);
    final records = docs
        .map((doc) => LoginHoursRecord.fromMap(doc.data(), id: doc.id))
        .where(
          (record) =>
              !record.date.isBefore(rangeStart) &&
              !record.date.isAfter(rangeEnd),
        )
        .toList();
    records.sort(_byDateThenName);
    return records;
  }

  int _byDateThenName(LoginHoursRecord a, LoginHoursRecord b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.employeeName.toLowerCase().compareTo(b.employeeName.toLowerCase());
  }

  @override
  Future<void> importFromBiometricRecords(
    List<BiometricDailyAttendance> records,
  ) async {
    if (records.isEmpty) return;

    try {
      final existingByKey = await _loadExistingRecords(records);
      const batchLimit = 450;
      var pendingWrites = <LoginHoursSyncDecision>[];

      for (final incoming in records) {
        final key = _recordKey(incoming.employeeId, incoming.date);
        final decision = _syncService.decide(
          existing: existingByKey[key],
          incoming: incoming,
        );
        if (decision.shouldWrite && decision.record != null) {
          pendingWrites.add(decision);
        }
      }

      for (var i = 0; i < pendingWrites.length; i += batchLimit) {
        final batch = _firestore.batch();
        final chunk = pendingWrites.skip(i).take(batchLimit);

        for (final decision in chunk) {
          final record = decision.record!;
          final docId = _documentId(
            record.employeeId,
            _formatDate(record.date),
          );
          final docRef = _collection.doc(docId);

          if (decision.action == LoginHoursSyncAction.create) {
            batch.set(docRef, record.toMap());
          } else if (decision.action == LoginHoursSyncAction.updateOutOnly) {
            batch.set(docRef, {
              'lastOut': record.lastOut,
              'status': record.status,
            }, SetOptions(merge: true));
          } else if (decision.action == LoginHoursSyncAction.correctSpan) {
            batch.set(docRef, {
              if (record.firstIn != null) 'firstIn': record.firstIn,
              if (record.lastOut != null) 'lastOut': record.lastOut,
              'status': record.status,
            }, SetOptions(merge: true));
          }
        }

        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to save login hours.',
        code: e.code,
      );
    }
  }

  @override
  Future<void> updateManually({
    required LoginHoursRecord record,
    required String firstIn,
    required String lastOut,
    required String status,
    required String remarks,
  }) async {
    try {
      final docId = _documentId(record.employeeId, _formatDate(record.date));
      final data = <String, dynamic>{
        'employeeId': record.employeeId,
        'employeeName': record.employeeName,
        'date': _formatDate(record.date),
        'status': status.trim(),
        'remarks': remarks,
        'manuallyEdited': true,
      };

      if (firstIn.trim().isNotEmpty) {
        data['firstIn'] = firstIn.trim();
      } else {
        data['firstIn'] = FieldValue.delete();
      }

      if (lastOut.trim().isNotEmpty) {
        data['lastOut'] = lastOut.trim();
      } else {
        data['lastOut'] = FieldValue.delete();
      }

      await _collection.doc(docId).set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to update login hours.',
        code: e.code,
      );
    }
  }

  Future<Map<String, LoginHoursRecord>> _loadExistingRecords(
    List<BiometricDailyAttendance> incoming,
  ) async {
    final dates = incoming.map((record) => _formatDate(record.date)).toSet();
    final existingByKey = <String, LoginHoursRecord>{};

    for (final date in dates) {
      final snapshot = await _collection.where('date', isEqualTo: date).get();
      for (final doc in snapshot.docs) {
        final record = LoginHoursRecord.fromMap(doc.data(), id: doc.id);
        existingByKey[record.recordKey] = record;
      }
    }

    return existingByKey;
  }

  String _recordKey(String employeeId, DateTime date) =>
      '${employeeId}_${_formatDate(date)}';

  String _documentId(String employeeId, String date) =>
      '${employeeId}_$date'.replaceAll('.', '_');

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

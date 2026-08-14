import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/holiday_calendar_document.dart';
import 'package:hr_portal/services/firebase_service.dart';

abstract class HolidayCalendarRepository {
  Stream<HolidayCalendarDocument?> watchCurrentCalendar();

  Future<void> uploadCalendar({
    required String fileName,
    required Uint8List fileBytes,
    required int year,
    required String uploadedBy,
  });
}

class HolidayCalendarRepositoryImpl implements HolidayCalendarRepository {
  HolidayCalendarRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseService.firestore,
       _storage = storage ?? FirebaseService.storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> get _currentDocument => _firestore
      .collection(AppConstants.holidayCalendarsCollection)
      .doc('current');

  @override
  Stream<HolidayCalendarDocument?> watchCurrentCalendar() {
    return _currentDocument.snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : HolidayCalendarDocument.fromMap(data);
    });
  }

  @override
  Future<void> uploadCalendar({
    required String fileName,
    required Uint8List fileBytes,
    required int year,
    required String uploadedBy,
  }) async {
    final previousPath = await _readPreviousStoragePath();

    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'holiday_calendars/$year/${timestamp}_$safeName';
    final reference = _storage.ref().child(storagePath);

    final downloadUrl = await _uploadPdf(
      reference: reference,
      fileBytes: fileBytes,
      year: year,
      uploadedBy: uploadedBy,
    );

    try {
      await _currentDocument.set({
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'storagePath': storagePath,
        'year': year,
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': uploadedBy,
      });
    } on FirebaseException catch (error) {
      await reference.delete().catchError((_) {});
      throw _failure('save the calendar entry', error);
    }

    if (previousPath != null && previousPath != storagePath) {
      _storage.ref().child(previousPath).delete().catchError((_) {});
    }
  }

  Future<String?> _readPreviousStoragePath() async {
    try {
      final snapshot = await _currentDocument.get();
      return snapshot.data()?['storagePath'] as String?;
    } on FirebaseException catch (error) {
      throw _failure('read the current calendar entry', error);
    }
  }

  Future<String> _uploadPdf({
    required Reference reference,
    required Uint8List fileBytes,
    required int year,
    required String uploadedBy,
  }) async {
    try {
      await reference.putData(
        fileBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {'year': '$year', 'uploadedBy': uploadedBy},
        ),
      );
      return await reference.getDownloadURL();
    } on FirebaseException catch (error) {
      await reference.delete().catchError((_) {});
      throw _failure('upload the PDF to storage', error);
    }
  }

  /// Names the failing step and origin plugin so permission errors are
  /// traceable to a specific Firestore or Storage rule.
  DataException _failure(String step, FirebaseException error) {
    return DataException(
      'Could not $step [${error.plugin}/${error.code}]: '
      '${error.message ?? 'unknown error'}',
      code: error.code,
    );
  }
}

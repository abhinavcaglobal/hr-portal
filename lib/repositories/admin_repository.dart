import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/constants/upload_file_types.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/upload_history_record.dart';
import 'package:hr_portal/services/firebase_service.dart';

abstract class AdminRepository {
  /// Records import in Firestore without uploading to Storage.
  Future<void> logImportHistory({
    required String fileName,
    required UploadType uploadType,
    required String uploadedBy,
    required String status,
    String? details,
  });

  /// Optional background archive to Storage (not required for import).
  Future<void> archiveFileToStorage({
    required String fileName,
    required UploadType uploadType,
    required String uploadedBy,
    required Uint8List fileBytes,
  });

  Stream<List<UploadHistoryRecord>> watchUploadHistory();
}

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseService.firestore,
      _storage = storage ?? FirebaseService.storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<void> logImportHistory({
    required String fileName,
    required UploadType uploadType,
    required String uploadedBy,
    required String status,
    String? details,
  }) async {
    try {
      await _firestore.collection(AppConstants.uploadHistoryCollection).add({
        'fileName': fileName,
        'uploadType': uploadType.value,
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': uploadedBy,
        'status': status,
        if (details != null) 'details': details,
      });
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to save upload history.',
        code: e.code,
      );
    }
  }

  @override
  Future<void> archiveFileToStorage({
    required String fileName,
    required UploadType uploadType,
    required String uploadedBy,
    required Uint8List fileBytes,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'uploads/${uploadType.value}/${timestamp}_$fileName';

      final ref = _storage.ref().child(storagePath);
      await ref
          .putData(
            fileBytes,
            SettableMetadata(
              contentType: UploadFileTypes.contentTypeFor(fileName),
              customMetadata: {
                'uploadType': uploadType.value,
                'uploadedBy': uploadedBy,
              },
            ),
          )
          .timeout(const Duration(seconds: 30));
    } on FirebaseException catch (e) {
      throw DataException(e.message ?? 'Storage archive failed.', code: e.code);
    } catch (_) {
      // Archiving is optional; import already succeeded.
    }
  }

  @override
  Stream<List<UploadHistoryRecord>> watchUploadHistory() {
    return _firestore
        .collection(AppConstants.uploadHistoryCollection)
        .orderBy('uploadedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UploadHistoryRecord.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}

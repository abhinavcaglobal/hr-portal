import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/attendance_record.dart';
import 'package:hr_portal/models/leave_request.dart';
import 'package:hr_portal/services/firebase_service.dart';
abstract class LeaveRequestRepository {
  Future<void> createRequest(LeaveRequest draft);

  Future<List<LeaveRequest>> getRequestsForEmployee(String employeeEmail);

  Stream<List<LeaveRequest>> watchRequestsForEmployee(String employeeEmail);

  Stream<List<LeaveRequest>> watchAllRequests();

  Future<LeaveRequestActionResult> approveRequest({
    required String requestId,
    required String adminId,
    String? adminComment,
    required String attendanceStatus,
    bool isUnpaid = false,
    String? employeeNote,
    double paidDeduction = 0,
  });

  Future<void> declineRequest({
    required String requestId,
    required String adminId,
    String? adminComment,
  });
}

class LeaveRequestActionResult {
  const LeaveRequestActionResult({
    required this.alreadyApproved,
    required this.request,
  });

  final bool alreadyApproved;
  final LeaveRequest request;
}

class LeaveRequestRepositoryImpl implements LeaveRequestRepository {
  LeaveRequestRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseService.firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(AppConstants.leaveRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _locks =>
      _firestore.collection(AppConstants.leaveRequestLocksCollection);

  CollectionReference<Map<String, dynamic>> get _attendance =>
      _firestore.collection(AppConstants.attendanceCollection);

  String _lockId(String email, DateTime date) =>
      '${email.trim().toLowerCase()}_${LeaveRequest.formatDate(date)}';

  String _attendanceDocId(String employeeName, DateTime date) {
    final dateStr = LeaveRequest.formatDate(date);
    return '${employeeName}_$dateStr'.replaceAll(' ', '_').replaceAll('.', '_');
  }

  @override
  Future<void> createRequest(LeaveRequest draft) async {
    try {
      final email = draft.employeeId.trim().toLowerCase();
      final lockRef = _locks.doc(_lockId(email, draft.leaveDate));
      final requestRef = _requests.doc();
      var alreadyExists = false;

      await _firestore.runTransaction((tx) async {
        final lockSnap = await tx.get(lockRef);
        if (lockSnap.exists) {
          // Do not throw Dart exceptions inside a web transaction — Flutter
          // web wraps them as an unreadable "converted Future" error.
          alreadyExists = true;
          return;
        }

        final now = DateTime.now();
        final data = LeaveRequest(
          requestId: requestRef.id,
          employeeId: email,
          employeeName: draft.employeeName,
          leaveDate: draft.leaveDate,
          leaveType: draft.leaveType,
          leaveDuration: draft.leaveDuration,
          leaveDeduction: draft.leaveDeduction,
          halfDayType: draft.halfDayType,
          fromTime: draft.fromTime,
          toTime: draft.toTime,
          reason: draft.reason,
          status: LeaveRequestStatus.pending,
          createdAt: now,
          updatedAt: now,
        ).toMap();

        tx.set(requestRef, data);
        tx.set(lockRef, {
          'employeeEmail': email,
          'leaveDate': LeaveRequest.formatDate(draft.leaveDate),
          'requestId': requestRef.id,
          'status': LeaveRequestStatus.pending,
        });
      });

      if (alreadyExists) {
        throw const DataException(
          'A leave request already exists for this date.',
        );
      }
    } on DataException {
      rethrow;
    } on FirebaseException catch (e) {
      throw DataException.fromUnknown(
        e,
        fallback: e.message ?? 'Failed to submit leave request.',
      );
    } catch (e) {
      throw DataException.fromUnknown(
        e,
        fallback: 'Failed to submit leave request.',
      );
    }
  }

  @override
  Future<List<LeaveRequest>> getRequestsForEmployee(String employeeEmail) async {
    try {
      final email = employeeEmail.trim().toLowerCase();
      final snapshot = await _requests
          .where('employeeEmail', isEqualTo: email)
          .get();
      final requests = snapshot.docs
          .map((doc) => LeaveRequest.fromMap(doc.data(), doc.id))
          .toList();
      requests.sort((a, b) => b.leaveDate.compareTo(a.leaveDate));
      return requests;
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load leave requests.',
        code: e.code,
      );
    }
  }

  @override
  Stream<List<LeaveRequest>> watchRequestsForEmployee(String employeeEmail) {
    final email = employeeEmail.trim().toLowerCase();
    return _requests.where('employeeEmail', isEqualTo: email).snapshots().map((
      snapshot,
    ) {
      final requests = snapshot.docs
          .map((doc) => LeaveRequest.fromMap(doc.data(), doc.id))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  @override
  Stream<List<LeaveRequest>> watchAllRequests() {
    return _requests.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => LeaveRequest.fromMap(doc.data(), doc.id))
          .toList();
      requests.sort(_adminSort);
      return requests;
    });
  }

  int _adminSort(LeaveRequest a, LeaveRequest b) {
    const rank = {
      LeaveRequestStatus.pending: 0,
      LeaveRequestStatus.approved: 1,
      LeaveRequestStatus.declined: 2,
    };
    final byStatus = (rank[a.status] ?? 9).compareTo(rank[b.status] ?? 9);
    if (byStatus != 0) return byStatus;
    return b.createdAt.compareTo(a.createdAt);
  }

  @override
  Future<LeaveRequestActionResult> approveRequest({
    required String requestId,
    required String adminId,
    String? adminComment,
    required String attendanceStatus,
    bool isUnpaid = false,
    String? employeeNote,
    double paidDeduction = 0,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final requestRef = _requests.doc(requestId);
        final snap = await tx.get(requestRef);
        if (!snap.exists) {
          throw const DataException('Leave request was not found.');
        }

        final current = LeaveRequest.fromMap(snap.data()!, snap.id);
        if (current.status == LeaveRequestStatus.approved) {
          return LeaveRequestActionResult(
            alreadyApproved: true,
            request: current,
          );
        }
        if (current.status != LeaveRequestStatus.pending) {
          throw const DataException('Only pending requests can be approved.');
        }

        final now = DateTime.now();
        tx.update(requestRef, {
          'status': LeaveRequestStatus.approved,
          'updatedAt': Timestamp.fromDate(now),
          'actionBy': adminId,
          'actionAt': Timestamp.fromDate(now),
          if (adminComment != null && adminComment.trim().isNotEmpty)
            'adminComment': adminComment.trim(),
          'isUnpaid': isUnpaid,
          'employeeNote': employeeNote,
          'paidDeduction': paidDeduction,
        });

        final attendanceRef = _attendance.doc(
          _attendanceDocId(current.employeeName, current.leaveDate),
        );
        final attendance = AttendanceRecord(
          employeeName: current.employeeName,
          employeeEmail: current.employeeEmail,
          date: current.leaveDate,
          status: attendanceStatus,
        );
        tx.set(attendanceRef, attendance.toMap(), SetOptions(merge: true));

        final lockRef = _locks.doc(
          _lockId(current.employeeEmail, current.leaveDate),
        );
        tx.set(lockRef, {
          'employeeEmail': current.employeeEmail,
          'leaveDate': LeaveRequest.formatDate(current.leaveDate),
          'requestId': current.requestId,
          'status': LeaveRequestStatus.approved,
        }, SetOptions(merge: true));

        return LeaveRequestActionResult(
          alreadyApproved: false,
          request: LeaveRequest.fromMap({
            ...snap.data()!,
            'status': LeaveRequestStatus.approved,
            'actionBy': adminId,
            'adminComment': adminComment,
            'isUnpaid': isUnpaid,
            'employeeNote': employeeNote,
            'paidDeduction': paidDeduction,
          }, snap.id),
        );
      });
    } on DataException {
      rethrow;
    } on FirebaseException catch (e) {
      throw DataException.fromUnknown(
        e,
        fallback: e.message ?? 'Failed to approve leave request.',
      );
    } catch (e) {
      throw DataException.fromUnknown(
        e,
        fallback: 'Failed to approve leave request.',
      );
    }
  }

  @override
  Future<void> declineRequest({
    required String requestId,
    required String adminId,
    String? adminComment,
  }) async {
    try {
      await _firestore.runTransaction((tx) async {
        final requestRef = _requests.doc(requestId);
        final snap = await tx.get(requestRef);
        if (!snap.exists) {
          throw const DataException('Leave request was not found.');
        }

        final current = LeaveRequest.fromMap(snap.data()!, snap.id);
        if (current.status == LeaveRequestStatus.declined) {
          return;
        }
        if (current.status != LeaveRequestStatus.pending) {
          throw const DataException('Only pending requests can be declined.');
        }

        final now = DateTime.now();
        tx.update(requestRef, {
          'status': LeaveRequestStatus.declined,
          'updatedAt': Timestamp.fromDate(now),
          'actionBy': adminId,
          'actionAt': Timestamp.fromDate(now),
          'adminComment': adminComment?.trim(),
        });

        final lockRef = _locks.doc(
          _lockId(current.employeeEmail, current.leaveDate),
        );
        tx.delete(lockRef);
      });
    } on DataException {
      rethrow;
    } on FirebaseException catch (e) {
      throw DataException.fromUnknown(
        e,
        fallback: e.message ?? 'Failed to decline leave request.',
      );
    } catch (e) {
      throw DataException.fromUnknown(
        e,
        fallback: 'Failed to decline leave request.',
      );
    }
  }
}

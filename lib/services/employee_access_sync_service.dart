import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/repositories/employee_repository.dart';
import 'package:hr_portal/services/firebase_service.dart';

class EmployeeAccessSyncResult {
  const EmployeeAccessSyncResult({
    required this.emailIndexCount,
    required this.attendancePatchedCount,
  });

  final int emailIndexCount;
  final int attendancePatchedCount;

  String get summary =>
      'Synced $emailIndexCount employee email mapping(s) and updated '
      '$attendancePatchedCount attendance record(s) with email addresses.';
}

class EmployeeAccessSyncService {
  EmployeeAccessSyncService({
    required EmployeeRepository employeeRepository,
    FirebaseFirestore? firestore,
  }) : _employeeRepository = employeeRepository,
       _firestore = firestore ?? FirebaseService.firestore;

  final EmployeeRepository _employeeRepository;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _emailIndex =>
      _firestore.collection(AppConstants.employeesByEmailCollection);

  CollectionReference<Map<String, dynamic>> get _attendance =>
      _firestore.collection(AppConstants.attendanceCollection);

  Future<EmployeeAccessSyncResult> syncAll() async {
    try {
      final employees = await _employeeRepository.getAllEmployees();
      final emailByName = await _syncEmailIndex(employees);
      final patchedCount = await _backfillAttendanceEmails(emailByName);

      return EmployeeAccessSyncResult(
        emailIndexCount: emailByName.length,
        attendancePatchedCount: patchedCount,
      );
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to sync employee access.',
        code: e.code,
      );
    }
  }

  Future<void> ensureEmailIndexForEmployee(Employee employee) async {
    final email = employee.email.trim().toLowerCase();
    if (email.isEmpty) return;

    await _emailIndex.doc(email).set({
      'email': email,
      'name': employee.name,
    }, SetOptions(merge: true));
  }

  Future<Map<String, String>> _syncEmailIndex(List<Employee> employees) async {
    final emailByName = <String, String>{};
    const batchLimit = 450;

    for (var i = 0; i < employees.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = employees.skip(i).take(batchLimit);

      for (final employee in chunk) {
        final email = employee.email.trim().toLowerCase();
        if (email.isEmpty) continue;

        emailByName[employee.name] = email;
        emailByName[_normalizeName(employee.name)] = email;
        batch.set(_emailIndex.doc(email), {
          'email': email,
          'name': employee.name,
        }, SetOptions(merge: true));
      }

      await batch.commit();
    }

    return emailByName;
  }

  String _normalizeName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String? _emailForAttendanceName(
    String attendanceName,
    Map<String, String> emailByName,
  ) {
    final trimmed = attendanceName.trim();
    if (emailByName.containsKey(trimmed)) {
      return emailByName[trimmed];
    }

    final normalized = _normalizeName(trimmed);
    if (emailByName.containsKey(normalized)) {
      return emailByName[normalized];
    }

    for (final entry in emailByName.entries) {
      if (_normalizeName(entry.key) == normalized) {
        return entry.value;
      }
    }

    return null;
  }

  Future<int> _backfillAttendanceEmails(Map<String, String> emailByName) async {
    if (emailByName.isEmpty) {
      return 0;
    }

    final snapshot = await _attendance.get();
    var patchedCount = 0;
    const batchLimit = 450;
    final pending = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = data['employeeName'] as String?;
      final currentEmail =
          (data['employeeEmail'] as String?)?.toLowerCase() ?? '';
      final mappedEmail = name != null
          ? _emailForAttendanceName(name, emailByName)
          : null;

      if (mappedEmail == null || currentEmail == mappedEmail) {
        continue;
      }

      pending.add(doc);
    }

    for (var i = 0; i < pending.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = pending.skip(i).take(batchLimit);

      for (final doc in chunk) {
        final name = doc.data()['employeeName'] as String;
        final mappedEmail = _emailForAttendanceName(name, emailByName)!;
        batch.set(doc.reference, {
          'employeeEmail': mappedEmail,
          'employeeName': name,
        }, SetOptions(merge: true));
        patchedCount++;
      }

      await batch.commit();
    }

    return patchedCount;
  }
}

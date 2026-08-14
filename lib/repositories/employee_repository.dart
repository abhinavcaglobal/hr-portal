import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/services/firebase_service.dart';

abstract class EmployeeRepository {
  Future<Employee?> getEmployeeByEmail(String email);
  Future<Employee?> getEmployeeByName(String name);
  Future<List<Employee>> getAllEmployees();
  Future<void> upsertEmployeeByName({
    required String name,
    required double openingBalance,
    String? email,
  });
  Future<void> importOpeningBalances(List<Employee> employees);
  Stream<Employee?> watchEmployeeByEmail(String email);
}

class EmployeeRepositoryImpl implements EmployeeRepository {
  EmployeeRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseService.firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.employeesCollection);

  @override
  Future<Employee?> getEmployeeByEmail(String email) async {
    try {
      final snapshot = await _collection
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        final altSnapshot = await _collection
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (altSnapshot.docs.isEmpty) return null;
        return Employee.fromMap(altSnapshot.docs.first.data());
      }

      return Employee.fromMap(snapshot.docs.first.data());
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load employee.',
        code: e.code,
      );
    }
  }

  @override
  Future<Employee?> getEmployeeByName(String name) async {
    try {
      final snapshot = await _collection
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Employee.fromMap(snapshot.docs.first.data());
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load employee.',
        code: e.code,
      );
    }
  }

  @override
  Future<List<Employee>> getAllEmployees() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) => Employee.fromMap(doc.data())).toList();
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to load employees.',
        code: e.code,
      );
    }
  }

  @override
  Future<void> upsertEmployeeByName({
    required String name,
    required double openingBalance,
    String? email,
  }) async {
    try {
      final existing = await getEmployeeByName(name);
      final employee = Employee(
        name: name,
        email: email ?? existing?.email ?? '',
        openingBalance: openingBalance,
      );

      await _collection
          .doc(_documentId(name))
          .set(employee.toMap(), SetOptions(merge: true));
      await _syncEmailIndexEntry(employee);
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to save employee.',
        code: e.code,
      );
    }
  }

  @override
  Future<void> importOpeningBalances(List<Employee> employees) async {
    try {
      const batchLimit = 450;
      for (var i = 0; i < employees.length; i += batchLimit) {
        final batch = _firestore.batch();
        final chunk = employees.skip(i).take(batchLimit);

        for (final employee in chunk) {
          final docRef = _collection.doc(_documentId(employee.name));
          batch.set(docRef, employee.toMap(), SetOptions(merge: true));
        }

        await batch.commit();

        for (final employee in chunk) {
          await _syncEmailIndexEntry(employee);
        }
      }
    } on FirebaseException catch (e) {
      throw DataException(
        e.message ?? 'Failed to import employees.',
        code: e.code,
      );
    }
  }

  String _documentId(String name) =>
      name.replaceAll(' ', '_').replaceAll('.', '_');

  CollectionReference<Map<String, dynamic>> get _emailIndex =>
      _firestore.collection(AppConstants.employeesByEmailCollection);

  Future<void> _syncEmailIndexEntry(Employee employee) async {
    final email = employee.email.trim().toLowerCase();
    if (email.isEmpty) return;

    await _emailIndex.doc(email).set({
      'email': email,
      'name': employee.name,
    }, SetOptions(merge: true));
  }

  @override
  Stream<Employee?> watchEmployeeByEmail(String email) {
    return _collection
        .where('email', isEqualTo: email)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Employee.fromMap(snapshot.docs.first.data());
        });
  }
}

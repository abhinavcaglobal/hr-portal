import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/providers/repository_providers.dart';
import 'package:hr_portal/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentEmployeeProvider = FutureProvider<Employee?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  final email = user?.email;
  if (email == null || email.isEmpty) {
    return null;
  }

  return ref.read(employeeRepositoryProvider).getEmployeeByEmail(email);
});

final isEmployeeSessionProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return false;
  }

  final employeeAsync = ref.watch(currentEmployeeProvider);
  return employeeAsync.valueOrNull != null;
});

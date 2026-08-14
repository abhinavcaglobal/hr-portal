import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/services/admin_auth_service.dart';
import 'package:hr_portal/services/auth_service.dart';

final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return const AdminAuthService();
});

final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, bool>((ref) {
  return AdminAuthNotifier(
    ref.watch(adminAuthServiceProvider),
    ref.watch(authServiceProvider),
  );
});

/// True when the signed-in Firebase user is the HR admin account (Ritu Sharma).
final isHrAdminAccountProvider = Provider<bool>((ref) {
  final email = ref.watch(authStateProvider).valueOrNull?.email;
  if (email == null) return false;
  return email.trim().toLowerCase() == AppConstants.adminEmail.toLowerCase();
});

class AdminAuthNotifier extends StateNotifier<bool> {
  AdminAuthNotifier(this._authService, this._firebaseAuthService)
    : super(false);

  final AdminAuthService _authService;
  final AuthService _firebaseAuthService;

  Future<bool> login({required String email, required String password}) async {
    final isValid = _authService.validateCredentials(
      email: email,
      password: password,
    );
    if (!isValid) {
      return false;
    }

    final currentUser = _firebaseAuthService.currentUser;
    final alreadySignedInAsAdmin =
        currentUser?.email?.toLowerCase() ==
        AppConstants.adminEmail.toLowerCase();

    if (!alreadySignedInAsAdmin) {
      await _firebaseAuthService.signIn(
        email: AppConstants.adminEmail,
        password: password,
      );
    }

    await _firebaseAuthService.ensureAdminSignedIn();

    state = true;
    return true;
  }

  /// Leaves the Firebase employee session active (for HR admin dual login).
  void logoutAdminOnly() => state = false;

  /// Signs out of Firebase and clears admin access.
  Future<void> logoutFully() async {
    state = false;
    await _firebaseAuthService.signOut();
  }
}

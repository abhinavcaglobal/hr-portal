import 'package:firebase_auth/firebase_auth.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/services/firebase_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseService.auth;

  final FirebaseAuth _auth;

  static bool isAllowedCompanyEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized.endsWith(AppConstants.allowedEmailDomain);
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool isAllowedEmail(String email) => isAllowedCompanyEmail(email);

  Future<User> signIn({required String email, required String password}) async {
    _validateEmailDomain(email);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Sign in failed. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageForFirebaseError(e), code: e.code);
    }
  }

  Future<User> signUp({required String email, required String password}) async {
    _validateEmailDomain(email);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Sign up failed. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageForFirebaseError(e), code: e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Ensures the Firebase ID token is ready before Firestore reads/writes.
  Future<User> ensureSignedIn() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        'Not signed in to Firebase. Please sign in again.',
      );
    }
    await user.getIdToken(true);
    return user;
  }

  Future<User> ensureAdminSignedIn() async {
    final user = await ensureSignedIn();
    if (user.email?.trim().toLowerCase() !=
        AppConstants.adminEmail.toLowerCase()) {
      throw AuthException(
        'Firebase account must be ${AppConstants.adminEmail} for admin uploads.',
      );
    }
    return user;
  }

  void _validateEmailDomain(String email) {
    if (!isAllowedCompanyEmail(email)) {
      throw AuthException(
        'Only ${AppConstants.allowedEmailDomain} work emails are allowed.',
      );
    }
  }

  String _messageForFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Invalid email or password.',
      'email-already-in-use' =>
        'An account already exists for this email. Try signing in.',
      'weak-password' => 'Password must be at least 6 characters.',
      'invalid-email' => 'Enter a valid email address.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      _ => e.message ?? 'Authentication failed.',
    };
  }
}

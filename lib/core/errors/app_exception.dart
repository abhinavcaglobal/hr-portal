class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class DataException extends AppException {
  const DataException(super.message, {super.code});

  /// Firestore web often wraps permission errors as a JS Promise conversion
  /// message instead of [FirebaseException].
  static DataException fromUnknown(Object error, {String fallback = 'Request failed.'}) {
    if (error is DataException) return error;
    if (error is AppException) {
      return DataException(error.message, code: error.code);
    }

    final text = error.toString();
    final lower = text.toLowerCase();
    if (lower.contains('permission-denied') ||
        lower.contains('permission_denied') ||
        lower.contains('missing or insufficient permissions')) {
      return const DataException(
        'Could not save the leave request. Publish the latest Firestore rules, then try again.',
        code: 'permission-denied',
      );
    }
    if (lower.contains('converted future') ||
        lower.contains('boxed error')) {
      return const DataException(
        'Could not save the leave request. If this continues, publish the latest Firestore rules and refresh the app.',
      );
    }
    return DataException(text.isEmpty ? fallback : text);
  }
}

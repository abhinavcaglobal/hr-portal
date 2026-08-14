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
}

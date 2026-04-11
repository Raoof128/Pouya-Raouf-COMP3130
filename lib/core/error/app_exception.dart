/// Base exception for all app-level errors.
sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Network-related failures (no connectivity, timeout, etc.).
class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

/// Authentication failures (invalid credentials, expired session, etc.).
class AuthException extends AppException {
  const AuthException(super.message, [super.cause]);
}

/// Server returned an unexpected response.
class ServerException extends AppException {
  const ServerException(String message, {this.statusCode, Object? cause})
    : super(message, cause);

  final int? statusCode;
}

/// Local storage read/write failure.
class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}

/// Feature not available (e.g. biometrics unsupported).
class UnsupportedException extends AppException {
  const UnsupportedException(super.message, [super.cause]);
}

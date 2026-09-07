// lib/core/errors/app_exception.dart

/// Base class for all application exceptions.
sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Thrown when a network/connectivity error occurs (no internet, timeout).
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
    super.code,
  });
}

/// Thrown when the server returns an unexpected error (5xx, 4xx).
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    this.statusCode,
    super.code,
  });
}

/// Thrown when reading/writing to local cache fails.
class CacheException extends AppException {
  const CacheException({
    super.message = 'Failed to access local cache.',
    super.code,
  });
}

/// Thrown for all Firebase Auth related errors.
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
  });

  /// Maps Firebase Auth error codes to user-friendly messages.
  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'user-not-found':
        return const AuthException(
          message: 'No account found with this email.',
          code: 'user-not-found',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException(
          message: 'Incorrect email or password.',
          code: 'wrong-password',
        );
      case 'email-already-in-use':
        return const AuthException(
          message: 'An account already exists with this email.',
          code: 'email-already-in-use',
        );
      case 'invalid-email':
        return const AuthException(
          message: 'Please enter a valid email address.',
          code: 'invalid-email',
        );
      case 'weak-password':
        return const AuthException(
          message: 'Password must be at least 6 characters.',
          code: 'weak-password',
        );
      case 'too-many-requests':
        return const AuthException(
          message: 'Too many attempts. Please try again later.',
          code: 'too-many-requests',
        );
      case 'network-request-failed':
        return const AuthException(
          message: 'Network error. Please check your connection.',
          code: 'network-request-failed',
        );
      case 'user-disabled':
        return const AuthException(
          message: 'This account has been disabled.',
          code: 'user-disabled',
        );
      default:
        return AuthException(
          message: 'Authentication error. Please try again.',
          code: code,
        );
    }
  }
}

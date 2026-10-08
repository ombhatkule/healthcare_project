/// Custom exceptions for the application.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'Network connection failed'});
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error occurred',
    super.statusCode,
  });
}

class CacheException extends AppException {
  const CacheException({super.message = 'Cache error occurred'});
}

class AuthException extends AppException {
  const AuthException({super.message = 'Authentication error'});
}

class ValidationException extends AppException {
  const ValidationException({super.message = 'Validation error'});
}

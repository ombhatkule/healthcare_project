/// Failure classes used in the domain layer for error handling.
abstract class Failure {
  final String message;
  const Failure({required this.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Network connection failed'});
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error occurred'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error occurred'});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication error'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'Validation error'});
}

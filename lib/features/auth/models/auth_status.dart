/// Represents the current authentication state of the application.
enum AuthStatus {
  /// Firebase has not yet determined the authentication state.
  unknown,

  /// User is not authenticated.
  unauthenticated,

  /// User is authenticated.
  authenticated,
}

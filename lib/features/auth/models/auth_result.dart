/// Data returned from a successful authentication operation.
class AuthResult {
  final String uid;
  final String email;
  final String? displayName;

  const AuthResult({
    required this.uid,
    required this.email,
    this.displayName,
  });
}

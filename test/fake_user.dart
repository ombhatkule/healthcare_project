import 'package:firebase_auth/firebase_auth.dart';

/// Minimal [User] stand-in for widget tests.
///
/// Only the members the app actually reads are implemented; everything else
/// is forwarded to [noSuchMethod] so the fake stays small and never touches
/// Firebase.
class FakeUser implements User {
  FakeUser({
    this.uid = 'test-uid',
    this.email = 'patient@example.com',
    this.displayName = 'Test Patient',
  });

  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

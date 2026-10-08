import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare_app/features/auth/models/auth_result.dart';
import 'package:healthcare_app/features/auth/services/auth_service.dart';

/// A fake [AuthService] for widget tests that avoids the real Firebase SDK.
class FakeAuthService extends AuthService {
  FakeAuthService({this.initialUser});

  /// The user emitted immediately when the auth stream is listened to.
  /// When null, the stream stays signed out until [emitSignedOut]/[emitUser].
  final User? initialUser;

  final _controller = StreamController<User?>.broadcast();

  @override
  Stream<User?> get authStateChanges async* {
    if (initialUser != null) yield initialUser;
    yield* _controller.stream;
  }

  @override
  User? get currentUser => initialUser;

  /// Simulate a signed-out auth state.
  void emitSignedOut() {
    _controller.add(null);
  }

  /// Emit the given user as the current logged-in state.
  void emitUser(User user) {
    _controller.add(user);
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return AuthResult(uid: 'test-uid', email: email, displayName: name);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return AuthResult(uid: 'test-uid', email: email, displayName: 'Test User');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

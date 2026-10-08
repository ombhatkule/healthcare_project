import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/errors/exceptions.dart';
import '../models/auth_result.dart';

/// Handles all Firebase authentication operations.
/// Encapsulates Firebase Auth and translates errors into AppExceptions.
class AuthService {
  final FirebaseAuth? _injectedAuth;

  AuthService({FirebaseAuth? auth}) : _injectedAuth = auth;

  /// Lazily resolve the Firebase Auth instance.
  /// Using a field-initialised instance would throw when Firebase is not
  /// initialized, so we resolve on demand. Tests inject a fake instance.
  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  /// Stream of current user. Emits null when logged out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Register a new user with email and password.
  /// Also sets the display name on the account.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException(
          message: 'Account created but user is not available.',
        );
      }

      // Set the user's display name.
      await user.updateDisplayName(name.trim());
      await user.reload();

      return AuthResult(
        uid: user.uid,
        email: user.email ?? email,
        displayName: user.displayName ?? name,
      );
    } on FirebaseAuthException catch (e) {
      // Keep the real error visible while debugging, then surface a friendly
      // message to the user.
      debugPrint('AuthService.register -> FirebaseAuthException[${e.code}]: '
          '${e.message}');
      throw AuthException(message: _mapRegisterError(e));
    }
  }

  /// Sign in an existing user.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException(message: 'Sign-in failed.');
      }

      return AuthResult(
        uid: user.uid,
        email: user.email ?? email,
        displayName: user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService.login -> FirebaseAuthException[${e.code}]: '
          '${e.message}');
      throw AuthException(message: _mapLoginError(e));
    }
  }

  /// Sign out the current user.
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapGenericError(e));
    }
  }

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapResetError(e));
    }
  }

  /// Map Firebase registration errors to friendly messages.
  String _mapRegisterError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email address is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'The email address is not valid. Please check it and try again.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled for this project.';
      case 'configuration-not-found':
        return 'Firebase configuration is not available. Please check the '
            'project settings and try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      default:
        return _mapGenericError(e);
    }
  }

  /// Map Firebase login errors to friendly messages.
  String _mapLoginError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please check or register.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your details.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'configuration-not-found':
        return 'Firebase configuration is not available. Please check the '
            'project settings and try again later.';
      default:
        return _mapGenericError(e);
    }
  }

  /// Map Firebase password reset errors to friendly messages.
  String _mapResetError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'missing-android-pkg-name':
      case 'missing-continue-uri':
      case 'invalid-continue-uri':
        return 'Password reset is misconfigured. Please contact support.';
      default:
        return _mapGenericError(e);
    }
  }

  /// Generic fallback error message.
  String _mapGenericError(FirebaseAuthException e) {
    if (e.code == 'network-request-failed') {
      return 'Network error. Please check your connection and try again.';
    }
    return e.message ?? 'An authentication error occurred. Please try again.';
  }
}

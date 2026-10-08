import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../services/auth_service.dart';
import '../../models/auth_status.dart';

/// State management for authentication.
/// Exposes login, register, logout, password reset, and auth state.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService) {
    _authStateSubscription = _authService.authStateChanges.listen(
      _onAuthChanged,
      onError: (Object error) {
        // A stream failure is a transport/initialization problem, never
        // proof that the user signed out: the status stays `unknown` so the
        // startup flow shows a retry state instead of opening login.
        debugPrint('Auth state stream error (${error.runtimeType}).');
      },
    );
  }

  late final StreamSubscription<User?> _authStateSubscription;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get userEmail => _user?.email;
  String? get displayName => _user?.displayName;
  String? get currentUid => _user?.uid;

  void _onAuthChanged(User? user) {
    _user = user;
    _status = user == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Register a new account.
  ///
  /// Returns the newly created user's UID on success, or `null` when
  /// registration failed. The returned UID is taken directly from the awaited
  /// Firebase Auth result so it is available immediately (independent of the
  /// async auth-state stream), which lets callers safely create a Firestore
  /// profile right after a successful sign-up.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      return result.uid;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      // Guard against non-Firebase/platform errors so the UI never crashes
      // and always shows a useful message.
      _errorMessage = 'Something went wrong during registration. '
          'Please try again.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Log in with email and password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.login(email: email, password: password);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Log the user out.
  Future<bool> logout() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.logout();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send a password reset email.
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear any displayed error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}

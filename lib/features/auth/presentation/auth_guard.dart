import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_status.dart';
import 'providers/auth_provider.dart';
import 'login_screen.dart';

/// A guard that protects a screen from being accessed when the user is not
/// authenticated. Wraps protected destinations.
///
/// - While the auth state is still being determined, shows a loader.
/// - If unauthenticated, redirects to the login screen.
/// - If authenticated, shows the wrapped [child].
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.unknown:
        // Auth state not yet resolved.
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticated:
        if (authProvider.status == AuthStatus.unauthenticated) {
          return const LoginScreen();
        }
        return child;
    }
  }
}

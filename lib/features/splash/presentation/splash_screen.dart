import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../auth/models/auth_status.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// Splash screen displayed when the application launches.
///
/// This screen keeps two concerns strictly separate:
///
///  * a minimum visual display duration (pure UX), and
///  * resolving the Firebase authentication state (pure navigation).
///
/// The app is only routed once BOTH are satisfied, so a slow Firebase
/// session restoration can never be mistaken for a signed-out user. The
/// splash screen is the single authority that decides where the app starts;
/// login, logout and the auth guard keep their existing behaviour.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.firebaseReady = true,
    this.onRetryStartup,
  });

  /// Whether Firebase finished initializing before the app was built.
  ///
  /// When `false` the authentication state can never resolve, so the screen
  /// shows a safe startup error instead of treating the failure as a
  /// signed-out user.
  final bool firebaseReady;

  /// Re-runs Firebase initialization after a startup failure.
  final Future<void> Function()? onRetryStartup;

  /// Earliest moment navigation is allowed. Visual only: it never decides
  /// which route the app opens.
  static const Duration minimumSplashDuration = Duration(seconds: 3);

  /// Safety net for a startup that never resolves an authentication state.
  /// Reaching it is an initialization problem, never proof of being logged
  /// out.
  static const Duration startupTimeout = Duration(seconds: 10);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Timer? _minimumDurationTimer;
  Timer? _startupTimeoutTimer;
  VoidCallback? _authListener;
  AuthProvider? _authProvider;

  bool _minimumDurationElapsed = false;
  bool _navigated = false;
  bool _startupFailed = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    // Visual minimum only. It marks the earliest moment a route may be
    // chosen; it never picks that route by itself.
    _minimumDurationTimer = Timer(SplashScreen.minimumSplashDuration, () {
      _minimumDurationElapsed = true;
      _navigateWhenReady();
    });

    if (widget.firebaseReady) {
      // Existing architecture: AuthProvider already wraps
      // FirebaseAuth.authStateChanges(), so the splash screen listens to it
      // instead of polling `currentUser` or guessing with a fixed delay.
      final authProvider = context.read<AuthProvider>();
      _authProvider = authProvider;
      _authListener = _handleAuthState;
      authProvider.addListener(_authListener!);
      _startupTimeoutTimer = Timer(
        SplashScreen.startupTimeout,
        _handleStartupTimeout,
      );
      // Covers a warm start where the state already resolved.
      _handleAuthState();
    } else {
      // Firebase never started: an initialization failure, not a
      // signed-out user. Fail fast into a retry state.
      _startupFailed = true;
    }
  }

  /// Reacts to every auth-state notification, including a state that
  /// resolves long after the minimum splash duration has passed.
  void _handleAuthState() {
    if (!mounted) return;
    _navigateWhenReady();
  }

  /// Navigates exactly once, and only when the auth state is resolved.
  void _navigateWhenReady() {
    if (_navigated || !mounted || !widget.firebaseReady) return;
    if (!_minimumDurationElapsed) return;

    final status = _authProvider?.status ?? AuthStatus.unknown;
    if (status == AuthStatus.unknown) {
      // Still restoring: keep waiting. Never assume signed-out.
      return;
    }

    _navigated = true;
    _cancelTimers();
    final route = status == AuthStatus.authenticated
        ? AppRoutes.home
        : AppRoutes.login;
    Navigator.of(context).pushReplacementNamed(route);
  }

  /// Safety net only. A timeout is reported as a startup problem and is
  /// never converted into "the user is logged out".
  void _handleStartupTimeout() {
    if (!mounted || _navigated) return;
    if ((_authProvider?.status ?? AuthStatus.unknown) != AuthStatus.unknown) {
      _navigateWhenReady();
      return;
    }
    setState(() => _startupFailed = true);
  }

  Future<void> _handleRetry() async {
    if (!widget.firebaseReady) {
      final retryStartup = widget.onRetryStartup;
      if (retryStartup == null) return;
      setState(() => _retrying = true);
      try {
        await retryStartup();
      } catch (_) {
        // Raw Firebase errors are never surfaced; the safe error state
        // simply stays on screen.
      } finally {
        if (mounted) setState(() => _retrying = false);
      }
      return;
    }

    // The auth state just has not arrived yet: keep waiting with a fresh
    // timeout window rather than assuming the user is signed out.
    if (!mounted) return;
    setState(() => _startupFailed = false);
    _startupTimeoutTimer?.cancel();
    _startupTimeoutTimer = Timer(
      SplashScreen.startupTimeout,
      _handleStartupTimeout,
    );
  }

  void _cancelTimers() {
    _minimumDurationTimer?.cancel();
    _minimumDurationTimer = null;
    _startupTimeoutTimer?.cancel();
    _startupTimeoutTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    final authProvider = _authProvider;
    final authListener = _authListener;
    if (authProvider != null && authListener != null) {
      authProvider.removeListener(authListener);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingXl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSizes.splashIconSize,
                  height: AppSizes.splashIconSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLg),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSm),
                const Text(
                  AppStrings.appTagline,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                if (_startupFailed) ...[
                  const SizedBox(height: AppSizes.paddingXl),
                  _buildStartupError(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Safe, exception-free startup error with a retry option. It is shown
  /// for initialization failures and for auth states that never resolved.
  Widget _buildStartupError() {
    final canRetry = widget.firebaseReady || widget.onRetryStartup != null;
    final isAuthTimeout = widget.firebaseReady;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 44,
          color: Colors.white70,
        ),
        const SizedBox(height: AppSizes.paddingMd),
        Text(
          isAuthTimeout
              ? AppStrings.authStateTimeoutTitle
              : AppStrings.startupErrorTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSm),
        Text(
          isAuthTimeout
              ? AppStrings.authStateTimeoutMessage
              : AppStrings.startupErrorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: Colors.white70,
          ),
        ),
        if (canRetry) ...[
          const SizedBox(height: AppSizes.paddingLg),
          if (_retrying)
            const Text(
              AppStrings.loading,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            )
          else
            ElevatedButton(
              onPressed: _handleRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              child: const Text(AppStrings.retry),
            ),
        ],
      ],
    );
  }
}

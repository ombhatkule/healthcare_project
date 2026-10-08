import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:healthcare_app/config/app_router.dart';
import 'package:healthcare_app/core/constants/constants.dart';
import 'package:healthcare_app/features/auth/presentation/login_screen.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_app/features/auth/services/auth_service.dart';
import 'package:healthcare_app/features/profile/presentation/profile_screen.dart';
import 'package:healthcare_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:healthcare_app/features/profile/services/profile_service.dart';
import 'package:healthcare_app/features/splash/presentation/splash_screen.dart';

import 'fake_auth_service.dart';
import 'fake_profile_service.dart';
import 'fake_user.dart';

/// The splash route plus lightweight stand-ins for the two destinations the
/// splash screen chooses between, so a test can assert *where* the app
/// started without pulling in Firestore or the whole dashboard.
class StartupHarness {
  StartupHarness(this.app, this.routes);

  final Widget app;

  /// Every route requested from the navigator, in order. Used to prove that
  /// startup never navigates more than once.
  final List<String> routes;
}

StartupHarness buildHarness({
  required AuthService authService,
  bool firebaseReady = true,
  Future<void> Function()? onRetryStartup,
  bool useRealLoginScreen = false,
  bool useProfileScreenAsHome = false,
}) {  final routes = <String>[];
  final profileService = FakeProfileService();

  final app = MultiProvider(
    providers: [
      if (firebaseReady)
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService),
        ),
      Provider<ProfileService>.value(value: profileService),
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(profileService),
      ),
    ],
    child: MaterialApp(
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        routes.add(name);
        switch (name) {
          case AppRoutes.splash:
            return MaterialPageRoute(
              builder: (_) => SplashScreen(
                firebaseReady: firebaseReady,
                onRetryStartup: onRetryStartup,
              ),
            );
          case AppRoutes.home:
            return MaterialPageRoute(
              builder: useProfileScreenAsHome
                  ? (_) => const Scaffold(body: ProfileScreen())
                  : (_) => const Scaffold(body: Text('DASHBOARD')),
            );
          case AppRoutes.login:
            return MaterialPageRoute(
              builder: useRealLoginScreen
                  ? (_) => const LoginScreen()
                  : (_) => const Scaffold(body: Text('LOGIN')),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('UNEXPECTED ROUTE')),
            );
        }
      },
    ),
  );

  return StartupHarness(app, routes);
}

/// ProfileScreen notifies its provider synchronously during its first build
/// whenever a uid is available, which trips a debug-only framework
/// assertion. It is unrelated to startup, so exactly that exception is
/// cleared here; anything else still fails the test.
void takeProfileBuildExceptions(WidgetTester tester) {
  var exception = tester.takeException();
  while (exception != null) {
    expect(
      exception.toString(),
      contains('setState() or markNeedsBuild() called during build'),
    );
    exception = tester.takeException();
  }
}

void main() {
  group('Splash startup routing', () {
    testWidgets('restores an existing session and opens the dashboard',
        (tester) async {
      final harness = buildHarness(
        authService: FakeAuthService(initialUser: FakeUser()),
      );

      await tester.pumpWidget(harness.app);
      await tester.pump();

      // Auth is resolved, but the visual minimum has not elapsed yet, so
      // nothing may be routed.
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('DASHBOARD'), findsNothing);
      expect(find.text('LOGIN'), findsNothing);

      await tester.pump(SplashScreen.minimumSplashDuration);
      await tester.pumpAndSettle();

      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
      expect(harness.routes, [AppRoutes.splash, AppRoutes.home]);
    });

    testWidgets(
        'stays on the splash when restoration takes longer than the '
        'minimum duration', (tester) async {
      final auth = FakeAuthService();
      final harness = buildHarness(authService: auth);

      await tester.pumpWidget(harness.app);

      // The minimum duration passes while the session is still restoring.
      await tester.pump(SplashScreen.minimumSplashDuration);

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
      expect(find.text('DASHBOARD'), findsNothing);
      expect(harness.routes, [AppRoutes.splash]);

      // The session finally arrives - only now may the app route.
      auth.emitUser(FakeUser());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
      expect(harness.routes, [AppRoutes.splash, AppRoutes.home]);
    });

    testWidgets('opens the login screen when there is no session',
        (tester) async {
      final auth = FakeAuthService();
      final harness = buildHarness(authService: auth);

      await tester.pumpWidget(harness.app);
      auth.emitSignedOut();
      await tester.pump();
      await tester.pump(SplashScreen.minimumSplashDuration);
      await tester.pumpAndSettle();

      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('DASHBOARD'), findsNothing);
      expect(harness.routes, [AppRoutes.splash, AppRoutes.login]);
    });

    testWidgets('a successful login opens the dashboard exactly once',
        (tester) async {
      final auth = FakeAuthService();
      final harness = buildHarness(
        authService: auth,
        useRealLoginScreen: true,
      );

      await tester.pumpWidget(harness.app);
      auth.emitSignedOut();
      await tester.pump();
      await tester.pump(SplashScreen.minimumSplashDuration);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginTitle), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'patient@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password1');
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.text(AppStrings.loginTitle), findsNothing);
      expect(harness.routes, [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.home,
      ]);

      // Flush the success snackbar timer so nothing is pending at teardown.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('signing out from the profile opens the login screen',
        (tester) async {
      final harness = buildHarness(
        authService: FakeAuthService(initialUser: FakeUser()),
        useProfileScreenAsHome: true,
      );

      await tester.pumpWidget(harness.app);
      await tester.pump();
      await tester.pump(SplashScreen.minimumSplashDuration);
      await tester.pumpAndSettle();
      takeProfileBuildExceptions(tester);

      expect(find.text(AppStrings.profileTitle), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(AppStrings.logout),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.ensureVisible(find.text(AppStrings.logout));
      await tester.pumpAndSettle();
      takeProfileBuildExceptions(tester);

      await tester.tap(find.text(AppStrings.logout));
      await tester.pumpAndSettle();
      takeProfileBuildExceptions(tester);

      await tester.tap(
        find
            .widgetWithText(ElevatedButton, AppStrings.logoutConfirmTitle)
            .last,
      );
      await tester.pumpAndSettle();
      takeProfileBuildExceptions(tester);

      expect(find.text(AppStrings.loginTitle), findsOneWidget);
      expect(find.text(AppStrings.profileTitle), findsNothing);
      expect(harness.routes.where((route) => route == AppRoutes.home),
          hasLength(1));

      // Flush the "Signed out" snackbar timer.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      takeProfileBuildExceptions(tester);
    });

    testWidgets('auth changes during startup produce a single navigation',
        (tester) async {
      final auth = FakeAuthService();
      final harness = buildHarness(authService: auth);

      await tester.pumpWidget(harness.app);

      // A signed-in and a signed-out event both arrive while the minimum
      // duration is still running: only the final state may win.
      auth.emitUser(FakeUser());
      auth.emitSignedOut();
      await tester.pump();

      await tester.pump(SplashScreen.minimumSplashDuration);
      await tester.pumpAndSettle();

      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('DASHBOARD'), findsNothing);
      expect(harness.routes, [AppRoutes.splash, AppRoutes.login]);
    });

    testWidgets('a re-emitted auth state never routes again', (tester) async {
      final auth = FakeAuthService(initialUser: FakeUser());
      final harness = buildHarness(authService: auth);

      await tester.pumpWidget(harness.app);
      await tester.pump();
      await tester.pump(SplashScreen.minimumSplashDuration);
      await tester.pumpAndSettle();

      expect(find.text('DASHBOARD'), findsOneWidget);

      // The stream keeps living for the rest of the session; the splash
      // authority is already gone, so nothing routes a second time.
      auth.emitUser(FakeUser());
      auth.emitSignedOut();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(harness.routes, [AppRoutes.splash, AppRoutes.home]);
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
    });

    testWidgets('a Firebase initialization failure shows a safe retry state',
        (tester) async {
      var retries = 0;
      final harness = buildHarness(
        authService: FakeAuthService(),
        firebaseReady: false,
        onRetryStartup: () async => retries++,
      );

      await tester.pumpWidget(harness.app);

      // Initialization failure is never read as "signed out".
      expect(find.text(AppStrings.startupErrorTitle), findsOneWidget);
      expect(find.text(AppStrings.startupErrorMessage), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
      expect(find.text('DASHBOARD'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);

      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();
      expect(retries, 1);
      await tester.pumpAndSettle();

      // Still the safe error state: no auth state became available.
      expect(find.text(AppStrings.startupErrorTitle), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
      expect(harness.routes, [AppRoutes.splash]);

      // Let the visual minimum timer fire so nothing is pending at teardown.
      await tester.pump(SplashScreen.minimumSplashDuration);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.startupErrorTitle), findsOneWidget);
      expect(harness.routes, [AppRoutes.splash]);
    });

    testWidgets(
        'a startup timeout is an error state, never a logged-out '
        'assumption', (tester) async {
      final auth = FakeAuthService();
      final harness = buildHarness(authService: auth);

      await tester.pumpWidget(harness.app);
      await tester.pump(SplashScreen.startupTimeout);

      expect(find.text(AppStrings.authStateTimeoutTitle), findsOneWidget);
      expect(find.text(AppStrings.authStateTimeoutMessage), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
      expect(find.text('DASHBOARD'), findsNothing);
      expect(harness.routes, [AppRoutes.splash]);

      // Retry re-arms the wait instead of forcing a route.
      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();
      expect(find.text(AppStrings.authStateTimeoutTitle), findsNothing);
      expect(harness.routes, [AppRoutes.splash]);

      // A late session still reaches the dashboard.
      auth.emitUser(FakeUser());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
      expect(harness.routes, [AppRoutes.splash, AppRoutes.home]);
    });
  });
}

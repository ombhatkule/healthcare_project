import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/constants/constants.dart';
import 'package:healthcare_app/features/splash/presentation/splash_screen.dart';
import 'package:healthcare_app/main.dart';
import 'fake_auth_service.dart';

void main() {
  testWidgets('App boots and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(HealthcareApp(authService: FakeAuthService()));

    // Verify the splash screen branding is displayed.
    expect(find.text('HealthCare AI'), findsOneWidget);
    expect(find.text('Your Personal Health Companion'), findsOneWidget);

    // Past the visual minimum the app must still sit on the splash: the
    // auth state has not resolved, so opening login would be a guess.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(AppStrings.loginTitle), findsNothing);

    // A startup that never resolves an auth state ends in a safe error
    // state with a retry option - never in a false "signed out" - and
    // leaves no timers pending.
    await tester.pump(SplashScreen.startupTimeout);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.authStateTimeoutTitle), findsOneWidget);
    expect(find.text(AppStrings.loginTitle), findsNothing);
  });
}

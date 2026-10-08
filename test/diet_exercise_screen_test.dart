import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/config/app_router.dart';
import 'package:healthcare_app/core/constants/constants.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/ai_assistant/presentation/providers/ai_assistant_controller.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_app/features/diet/presentation/screens/diet_screen.dart';
import 'package:healthcare_app/features/diet_exercise/presentation/providers/diet_exercise_controller.dart';
import 'package:healthcare_app/features/exercise/presentation/screens/exercise_screen.dart';
import 'package:healthcare_app/features/home/presentation/home_screen.dart';
import 'package:healthcare_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

import 'fake_ai_assistant_service.dart';
import 'fake_appointment_service.dart';
import 'fake_auth_service.dart';
import 'fake_diet_exercise_services.dart';
import 'fake_medical_record_service.dart';
import 'fake_prescription_service.dart';
import 'fake_profile_service.dart';

/// An [AuthProvider] that reports a signed-in user.
class _SignedInAuthProvider extends AuthProvider {
  _SignedInAuthProvider() : super(FakeAuthService());

  @override
  String? get currentUid => 'test-uid';
}

/// Scrolls [finder] into view before tapping it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// Builds a fully-provided app so a route pushed with [AppRouter] has the
/// providers the destination module expects.
Widget _app({required Widget home}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _SignedInAuthProvider(),
      ),
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(FakeProfileService()),
      ),
      ChangeNotifierProvider<DietExerciseController>(
        create: (_) => DietExerciseController(
          dietService: FakeDietService(),
          exerciseService: FakeExerciseService(),
          activityService: FakeActivityTrackingService(),
        ),
      ),
      ChangeNotifierProvider<AiAssistantController>(
        create: (_) => AiAssistantController(
          FakeAiAssistantService(),
          medicalRecordService: FakeMedicalRecordService(),
          prescriptionService: FakePrescriptionService(),
          appointmentService: FakeAppointmentService(),
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: home,
      onGenerateRoute: AppRouter.generateRoute,
    ),
  );
}

void main() {
  group('Legacy routes', () {
    testWidgets('legacy diet and exercise routes still resolve',
        (tester) async {
      await tester.pumpWidget(
        _app(
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.dietRecommendation),
                    child: const Text('diet'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.exerciseRecommendation),
                    child: const Text('exercise'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('diet'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.dietPlanTitle), findsWidgets);
      expect(find.byKey(const Key('diet_plan_ask_ai_button')), findsOneWidget);

      await _tap(tester, find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('exercise'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.exerciseLibraryLabel), findsWidgets);
    });

    testWidgets('the legacy combined route opens the Diet screen',
        (tester) async {
      await tester.pumpWidget(
        _app(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.dietExercise),
                child: const Text('open-legacy'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-legacy'));
      await tester.pumpAndSettle();

      expect(find.byType(DietScreen), findsOneWidget);
      expect(find.text(AppStrings.yourDietPlan), findsWidgets);
    });
  });

  group('Home dashboard integration', () {
    testWidgets('the Diet and Exercise tiles open their own modules',
        (tester) async {
      // The dashboard only needs the auth provider; the module providers below
      // are the ones the pushed module routes expect.
      await tester.pumpWidget(_app(home: const HomeScreen()));
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Diet'));
      await tester.pumpAndSettle();

      expect(find.byType(DietScreen), findsOneWidget);
      expect(find.text(AppStrings.yourDietPlan), findsWidgets);
      // The Exercise module must not leak onto the Diet screen.
      expect(find.byType(ExerciseScreen), findsNothing);
      expect(find.text(AppStrings.todaysExerciseLabel), findsNothing);

      await _tap(tester, find.byType(BackButton));
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Exercise'));
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseScreen), findsOneWidget);
      expect(find.text(AppStrings.yourExercisePlan), findsWidgets);
      expect(find.text(AppStrings.waterIntakeLabel), findsWidgets);
    });
  });
}
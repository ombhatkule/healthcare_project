import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/config/app_router.dart';
import 'package:healthcare_app/core/constants/constants.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/ai_assistant/presentation/providers/ai_assistant_controller.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_app/features/diet/presentation/screens/diet_screen.dart';
import 'package:healthcare_app/features/diet_exercise/models/models.dart';
import 'package:healthcare_app/features/diet_exercise/presentation/providers/diet_exercise_controller.dart';
import 'package:healthcare_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:healthcare_app/features/profile/models/user_profile.dart';
import 'package:healthcare_app/shared/widgets/widgets.dart';
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

/// A signed-out provider, i.e. the default [FakeAuthService] state.
class _SignedOutAuthProvider extends AuthProvider {
  _SignedOutAuthProvider() : super(FakeAuthService());

  @override
  String? get currentUid => null;
}

/// A [ProfileProvider] that reports a fixed profile.
class _ProfileWithDataProvider extends ProfileProvider {
  _ProfileWithDataProvider(this._data) : super(FakeProfileService());

  final UserProfile? _data;

  @override
  UserProfile? get profile => _data;
}

Widget _app({
  required DietExerciseController controller,
  bool signedIn = true,
  UserProfile? profile,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) =>
            signedIn ? _SignedInAuthProvider() : _SignedOutAuthProvider(),
      ),
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => profile == null
            ? ProfileProvider(FakeProfileService())
            : _ProfileWithDataProvider(profile),
      ),
      ChangeNotifierProvider<DietExerciseController>.value(value: controller),
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
      home: const DietScreen(),
      onGenerateRoute: AppRouter.generateRoute,
    ),
  );
}

DietExerciseController _controller({
  FakeDietService? dietService,
  FakeExerciseService? exerciseService,
  FakeActivityTrackingService? activityService,
}) {
  return DietExerciseController(
    dietService: dietService ?? FakeDietService(),
    exerciseService: exerciseService ?? FakeExerciseService(),
    activityService: activityService ?? FakeActivityTrackingService(),
  );
}

/// Scrolls [finder] into view before tapping it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  group('Diet module rendering', () {
    testWidgets('shows the goal, meal summary and AI entry', (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      expect(find.byType(DietScreen), findsOneWidget);
      expect(find.text(AppStrings.yourDietPlan), findsWidgets);
      expect(find.text(AppStrings.todaysGoalLabel), findsWidgets);
      expect(find.byKey(const Key('wellness_goal_card')), findsOneWidget);
      expect(find.text(AppStrings.todaysDietPlanLabel), findsWidgets);
      expect(find.text(AppStrings.askAiAboutDiet), findsWidgets);
    });

    testWidgets('contains no exercise, water or progress content',
        (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('start_workout_button')), findsNothing);
      expect(find.byKey(const Key('water_increment')), findsNothing);
      expect(find.byKey(const Key('view_progress_button')), findsNothing);
      expect(find.text(AppStrings.exerciseLibraryLabel), findsNothing);
      expect(find.text(AppStrings.todaysExerciseLabel), findsNothing);
    });

    testWidgets('starts with an empty but usable goal', (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.notSpecifiedLabel), findsWidgets);
      expect(find.textContaining('General Activity'), findsWidgets);
      expect(find.textContaining(AppStrings.approximateLabel), findsWidgets);
    });

    testWidgets('shows a locked screen and offers sign in when signed out',
        (tester) async {
      await tester.pumpWidget(_app(controller: _controller(), signedIn: false));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.signInToTrack), findsOneWidget);
      expect(find.text(AppStrings.continueButton), findsOneWidget);
      expect(find.byKey(const Key('wellness_goal_card')), findsNothing);
    });

    testWidgets('renders on a small screen without overflowing',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DietScreen), findsOneWidget);
    });
  });

  group('Loading and error states', () {
    testWidgets('surfaces a load error and can retry', (tester) async {
      final dietService = FakeDietService(shouldThrow: true);
      final controller = _controller(dietService: dietService);

      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Firestore unavailable'), findsWidgets);

      dietService.shouldThrow = false;
      await _tap(tester, find.text(AppStrings.retry));
      await tester.pumpAndSettle();

      expect(find.textContaining('Firestore unavailable'), findsNothing);
      expect(find.text(AppStrings.viewFullDietPlan), findsWidgets);
    });

    testWidgets('a load failure reports the error without blocking the module',
        (tester) async {
      final dietService = FakeDietService(shouldThrow: true);
      final controller = _controller(dietService: dietService);

      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Firestore unavailable'), findsWidgets);
      expect(
        find.byKey(const Key('diet_exercise_retry_action')),
        findsOneWidget,
      );
      // ...but the diet content is never replaced by a dead-end screen.
      expect(find.byKey(const Key('wellness_goal_card')), findsOneWidget);
      expect(find.text(AppStrings.viewFullDietPlan), findsWidgets);
      expect(find.textContaining('Something went wrong'), findsNothing);
    });

    testWidgets('a preference failure never shows the full-screen error state',
        (tester) async {
      final dietService = FakeDietService(shouldThrow: true);
      final controller = _controller(dietService: dietService);

      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.textContaining('Something went wrong'), findsNothing);
      expect(
        find.textContaining('Unable to load your diet preferences'),
        findsNothing,
      );
      expect(find.textContaining('Retry'), findsOneWidget);

      // Everything local still renders.
      expect(find.byType(DietScreen), findsOneWidget);
      expect(find.byKey(const Key('wellness_goal_card')), findsOneWidget);
      expect(find.text(AppStrings.viewFullDietPlan), findsWidgets);
      expect(find.byKey(const Key('ask_ai_assistant_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Diet navigation', () {
    testWidgets('the wellness goal card opens the preferences screen',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('wellness_goal_card')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.wellnessPreferencesTitle), findsWidgets);
      expect(find.byKey(const Key('save_preferences_button')), findsOneWidget);
    });

    testWidgets('saving preferences updates the goal shown on the screen',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('diet_preferences_action')));
      await tester.pumpAndSettle();

      final option = find.byKey(
        Key('option_${AppStrings.wellnessGoalLabel}_'
            '${WellnessGoal.improveActivity.label}'),
      );
      await _tap(tester, option);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<InkWell>(
              find.descendant(
                of: option,
                matching: find.byType(InkWell),
              ),
            )
            .onTap,
        isNotNull,
      );

      await _tap(tester, find.byKey(const Key('save_preferences_button')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.wellnessPreferencesTitle), findsNothing);

      expect(controller.preferences.goal, WellnessGoal.improveActivity);
      expect(controller.preferences.hasSelectedGoal, isTrue);
      expect(find.text(WellnessGoal.improveActivity.label), findsWidgets);
    });

    testWidgets('view full plan lists every meal with a disclaimer',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      await _tap(tester, find.text(AppStrings.viewFullDietPlan));
      await tester.pumpAndSettle();

      for (final slot in MealSlot.values) {
        expect(find.text(slot.label), findsWidgets);
      }
      expect(find.textContaining(AppStrings.approximateLabel), findsWidgets);
      expect(find.textContaining('not a substitute'), findsWidgets);
    });

    testWidgets('allergies from the profile are surfaced with a warning',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(
        _app(
          controller: controller,
          profile: const UserProfile(
            uid: 'test-uid',
            fullName: 'Asha',
            email: 'asha@example.com',
            allergies: 'Peanuts',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _tap(tester, find.text(AppStrings.viewFullDietPlan));
      await tester.pumpAndSettle();

      expect(find.textContaining('Peanuts'), findsWidgets);
    });

    testWidgets('the AI Assistant button opens the assistant screen',
        (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('ask_ai_assistant_button')));
      await tester.pumpAndSettle();

      expect(find.text('AI Healthcare Assistant'), findsOneWidget);
    });

    testWidgets('the app bar assistant icon opens the assistant screen',
        (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('diet_ai_action')));
      await tester.pumpAndSettle();

      expect(find.text('AI Healthcare Assistant'), findsOneWidget);
    });
  });
}
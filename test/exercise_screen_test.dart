import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/config/app_router.dart';
import 'package:healthcare_app/core/constants/constants.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/ai_assistant/presentation/providers/ai_assistant_controller.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_app/features/diet_exercise/models/models.dart';
import 'package:healthcare_app/features/diet_exercise/presentation/providers/diet_exercise_controller.dart';
import 'package:healthcare_app/features/exercise/presentation/screens/exercise_screen.dart';
import 'package:healthcare_app/features/profile/presentation/providers/profile_provider.dart';
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

Widget _app({required DietExerciseController controller}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _SignedInAuthProvider(),
      ),
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(FakeProfileService()),
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
      home: const ExerciseScreen(),
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
  group('Exercise module rendering', () {
    testWidgets('shows progress, water, routine and the library',
        (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseScreen), findsOneWidget);
      expect(find.text(AppStrings.yourExercisePlan), findsWidgets);
      expect(find.text(AppStrings.todaysProgressLabel), findsWidgets);
      expect(find.text(AppStrings.waterIntakeLabel), findsWidgets);
      expect(find.text(AppStrings.exerciseProgressLabel), findsWidgets);
      expect(find.byKey(const Key('start_workout_button')), findsOneWidget);
      expect(find.byKey(const Key('view_progress_button')), findsOneWidget);
      expect(find.text(AppStrings.exerciseLibraryLabel), findsWidgets);
    });

    testWidgets('contains no diet meal content', (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wellness_goal_card')), findsNothing);
      expect(find.text(AppStrings.todaysDietPlanLabel), findsNothing);
      expect(find.text(AppStrings.todaysGoalLabel), findsNothing);
    });

    testWidgets('starts with an empty but usable day', (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      expect(find.text('0 / ${HydrationRecord.defaultGoal}'), findsWidgets);
    });

    testWidgets('renders on a small screen without overflowing',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ExerciseScreen), findsOneWidget);
    });
  });

  group('Loading and error states', () {
    testWidgets('surfaces a load error and can retry', (tester) async {
      final exerciseService = FakeExerciseService(shouldThrow: true);
      final controller = _controller(exerciseService: exerciseService);

      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Firestore unavailable'), findsWidgets);

      exerciseService.shouldThrow = false;
      await _tap(tester, find.text(AppStrings.retry));
      await tester.pumpAndSettle();

      expect(find.textContaining('Firestore unavailable'), findsNothing);
      expect(find.byKey(const Key('start_workout_button')), findsOneWidget);
    });

    testWidgets('a load failure does not block the library or routine',
        (tester) async {
      final exerciseService = FakeExerciseService(shouldThrow: true);
      final controller = _controller(exerciseService: exerciseService);

      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Firestore unavailable'), findsWidgets);
      expect(
        find.byKey(const Key('diet_exercise_retry_action')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('start_workout_button')), findsOneWidget);
      expect(find.text(AppStrings.exerciseLibraryLabel), findsWidgets);
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
      expect(find.textContaining('Retry'), findsOneWidget);

      expect(find.byType(ExerciseScreen), findsOneWidget);
      expect(find.byKey(const Key('water_increment')), findsOneWidget);
      expect(find.byKey(const Key('start_workout_button')), findsOneWidget);
      expect(find.byKey(const Key('view_progress_button')), findsOneWidget);
      expect(find.text(AppStrings.exerciseLibraryLabel), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Water tracking', () {
    testWidgets('the plus button adds a glass and the minus removes it',
        (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('water_increment')));
      await tester.pumpAndSettle();
      expect(find.text('1 / ${HydrationRecord.defaultGoal}'), findsWidgets);

      await _tap(tester, find.byKey(const Key('water_decrement')));
      await tester.pumpAndSettle();
      expect(find.text('0 / ${HydrationRecord.defaultGoal}'), findsWidgets);
    });

    testWidgets('the water count never drops below zero', (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await _tap(tester, find.byKey(const Key('water_decrement')));
        await tester.pumpAndSettle();
      }

      expect(controller.waterGlasses, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unreachable Firestore rolls the count back',
        (tester) async {
      final activityService = FakeActivityTrackingService();
      final controller = _controller(activityService: activityService);

      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('water_increment')));
      await tester.pumpAndSettle();
      expect(controller.waterGlasses, 1);

      activityService.shouldThrow = true;
      await _tap(tester, find.byKey(const Key('water_increment')));
      await tester.pumpAndSettle();

      expect(controller.waterGlasses, 1, reason: 'optimistic value rolled back');
      expect(find.textContaining('Firestore unavailable'), findsWidgets);
    });
  });

  group('Exercise completion', () {
    testWidgets('tapping the tick marks an exercise done', (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      final exercise = controller.dailyRoutine.first;
      await _tap(tester, find.byKey(Key('exercise_complete_${exercise.id}')));
      await tester.pumpAndSettle();

      expect(controller.isExerciseCompleted(exercise.id), isTrue);
      expect(controller.exerciseMinutes, exercise.durationMinutes);

      await _tap(tester, find.byKey(Key('exercise_complete_${exercise.id}')));
      await tester.pumpAndSettle();

      expect(controller.isExerciseCompleted(exercise.id), isFalse);
      expect(controller.exerciseMinutes, 0);
    });
  });

  group('Exercise navigation', () {
    testWidgets('start workout opens the first incomplete exercise',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('start_workout_button')));
      await tester.pumpAndSettle();

      expect(find.text(controller.dailyRoutine.first.name), findsWidgets);
      expect(find.byKey(const Key('exercise_detail_mark_completed')),
          findsOneWidget);
    });

    testWidgets('the exercise library can be filtered and opened',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('exercise_category_all')));
      await tester.pumpAndSettle();

      final first = controller.exerciseCatalog.first;
      await _tap(tester, find.text(first.name));
      await tester.pumpAndSettle();

      expect(find.text(first.instructions), findsWidgets);
      expect(find.textContaining(first.safetyNote, findRichText: true),
          findsWidgets);
    });

    testWidgets('opening an exercise never marks it completed',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      final first = controller.exerciseCatalog.first;
      await _tap(tester, find.text(first.name));
      await tester.pumpAndSettle();

      expect(controller.completedExerciseCount, 0);
      expect(controller.exerciseMinutes, 0);
    });

    testWidgets('the detail screen marks an exercise as completed',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('start_workout_button')));
      await tester.pumpAndSettle();

      final exercise = controller.dailyRoutine.first;
      await _tap(
          tester, find.byKey(const Key('exercise_detail_mark_completed')));
      await tester.pumpAndSettle();

      expect(controller.isExerciseCompleted(exercise.id), isTrue);
      expect(find.byKey(const Key('exercise_detail_completed')), findsOneWidget);
    });

    testWidgets('the progress screen shows seven days of data',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('view_progress_button')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.progressTitle), findsWidgets);
      expect(find.textContaining(AppStrings.lastSevenDaysLabel), findsWidgets);
      expect(find.byKey(const Key('progress_open_activity')), findsOneWidget);
    });

    testWidgets('the activity screen logs a manual entry and steps',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('view_progress_button')));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('progress_open_activity')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noActivityLogged), findsOneWidget);

      await _tap(tester, find.byKey(const Key('add_activity_fab')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('activity_name_field')), 'Brisk walk');
      await tester.enterText(
          find.byKey(const Key('activity_minutes_field')), '25');
      await tester.enterText(
          find.byKey(const Key('activity_steps_field')), '3200');
      await _tap(tester, find.byKey(const Key('save_activity_button')));
      await tester.pumpAndSettle();

      expect(controller.activityEntries.single.name, 'Brisk walk');
      expect(controller.steps, 3200);
      expect(find.text('Brisk walk'), findsOneWidget);
      expect(find.textContaining('25'), findsWidgets);
    });

    testWidgets('the activity form rejects an empty name', (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('view_progress_button')));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('progress_open_activity')));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('add_activity_fab')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('activity_minutes_field')), '20');
      await _tap(tester, find.byKey(const Key('save_activity_button')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.activityNameRequired), findsOneWidget);
      expect(controller.activityEntries, isEmpty);
    });

    testWidgets('the AI Assistant button opens the assistant screen',
        (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('exercise_ask_ai_button')));
      await tester.pumpAndSettle();

      expect(find.text('AI Healthcare Assistant'), findsOneWidget);
    });

    testWidgets('the app bar assistant icon opens the assistant screen',
        (tester) async {
      await tester.pumpWidget(_app(controller: _controller()));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const Key('exercise_ai_action')));
      await tester.pumpAndSettle();

      expect(find.text('AI Healthcare Assistant'), findsOneWidget);
    });
  });
}
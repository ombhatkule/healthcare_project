import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/errors/exceptions.dart';
import 'package:healthcare_app/features/diet_exercise/models/models.dart';
import 'package:healthcare_app/features/diet_exercise/presentation/providers/diet_exercise_controller.dart';
import 'package:healthcare_app/features/diet_exercise/services/services.dart';
import 'package:healthcare_app/features/profile/models/user_profile.dart';

import 'fake_diet_exercise_services.dart';

void main() {
  const uid = 'user-1';

  late FakeDietService dietService;
  late FakeExerciseService exerciseService;
  late FakeActivityTrackingService activityService;
  late DietExerciseController controller;

  setUp(() {
    dietService = FakeDietService();
    exerciseService = FakeExerciseService();
    activityService = FakeActivityTrackingService();
    controller = DietExerciseController(
      dietService: dietService,
      exerciseService: exerciseService,
      activityService: activityService,
    );
  });

  String today() => dateKeyOf(DateTime.now());

  group('Empty state', () {
    test('load with no stored documents returns usable defaults', () async {
      await controller.load(uid);

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.date, today());
      expect(controller.waterGlasses, 0);
      expect(controller.waterGoal, HydrationRecord.defaultGoal);
      expect(controller.exerciseMinutes, 0);
      expect(controller.completedExerciseCount, 0);
      expect(controller.steps, 0);
      expect(controller.activityEntries, isEmpty);
      expect(controller.dietPlan.meals, isNotEmpty);
      expect(controller.dailyRoutine, isNotEmpty);
    });

    test('reset clears everything so nothing leaks into the next session', () async {
      await controller.load(uid);
      await controller.incrementWater(uid);
      controller.reset();

      expect(controller.date, '');
      expect(controller.waterGlasses, 0);
      expect(controller.isSignedIn, isFalse);
      expect(controller.preferences, const DietExercisePreferences());
    });

    test('refresh before a user is loaded does nothing', () async {
      await controller.refresh();

      expect(controller.date, '');
      expect(controller.hasError, isFalse);
    });
  });

  group('Firestore error state', () {
    test('a failed load surfaces a message and stops loading', () async {
      dietService.shouldThrow = true;

      await controller.load(uid);

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, isNotEmpty);
    });

    test('a failed water write rolls the value back', () async {
      await controller.load(uid);
      activityService.shouldThrow = true;

      final saved = await controller.incrementWater(uid);

      expect(saved, isFalse);
      expect(controller.waterGlasses, 0, reason: 'optimistic value rolled back');
      expect(controller.hasError, isTrue);
    });

    test('a failed workout write rolls the completion back', () async {
      await controller.load(uid);
      exerciseService.shouldThrow = true;
      final exercise = controller.exerciseCatalog.first;

      final saved = await controller.toggleExercise(uid, exercise);

      expect(saved, isFalse);
      expect(controller.isExerciseCompleted(exercise.id), isFalse);
      expect(controller.exerciseMinutes, 0);
      expect(controller.hasError, isTrue);
    });

    test('a failed activity write rolls the entry back', () async {
      await controller.load(uid);
      activityService.shouldThrow = true;

      final saved = await controller.addActivityEntry(uid, name: 'Walk', minutes: 20);

      expect(saved, isFalse);
      expect(controller.activityEntries, isEmpty);
      expect(controller.hasError, isTrue);
    });

    test('a failed preferences write restores the previous state', () async {
      await controller.load(uid);
      dietService.shouldThrow = true;

      final saved = await controller.savePreferences(
        uid,
        const DietExercisePreferences(
          goal: WellnessGoal.improveActivity,
          waterGoal: 12,
        ),
      );

      expect(saved, isFalse);
      expect(controller.preferences.goal, WellnessGoal.generalFitness);
      expect(controller.waterGoal, HydrationRecord.defaultGoal);
      expect(controller.hasError, isTrue);
    });

    test('clearError removes the message', () async {
      dietService.shouldThrow = true;
      await controller.load(uid);
      expect(controller.hasError, isTrue);

      controller.clearError();

      expect(controller.hasError, isFalse);
    });
  });

  group('Partial Firestore failure', () {
    test('one failed read still returns a fully usable day', () async {
      dietService.shouldThrow = true;

      await controller.load(uid);

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, contains('Firestore unavailable'));

      // Defaults keep the rest of the module alive.
      expect(controller.date, today());
      expect(controller.hydration.date, today(),
          reason: 'a failed slice must not blank the day');
      expect(controller.dietPlan.meals, isNotEmpty);
      expect(controller.dailyRoutine, isNotEmpty);
      expect(controller.waterGlasses, 0);
      expect(controller.exerciseMinutes, 0);
    });

    test('every slice failing still leaves the screen usable', () async {
      dietService.shouldThrow = true;
      exerciseService.shouldThrow = true;
      activityService.shouldThrow = true;

      await controller.load(uid);

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, isNotEmpty);
      expect(controller.dietPlan.meals, isNotEmpty);
      expect(controller.dailyRoutine, isNotEmpty);
      expect(controller.hydration.date, today());
    });

    test('a successful reload clears the collected failures', () async {
      dietService.shouldThrow = true;
      await controller.load(uid);
      expect(controller.hasError, isTrue);

      dietService.shouldThrow = false;
      await controller.load(uid);

      expect(controller.hasError, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('history falls back to empty days when a query fails', () async {
      activityService.shouldThrow = true;

      await controller.loadHistory(uid);

      expect(controller.isHistoryLoading, isFalse);
      expect(controller.hasError, isTrue);
      expect(controller.history, hasLength(7));
      expect(
        controller.history.every((day) => day.waterGlasses == 0),
        isTrue,
      );
    });
  });

  group('Optional preferences never block the module', () {
    test('permission denied keeps every static section and stops loading',
        () async {
      dietService.failure = Exception(
        '[firebase_firestore/permission-denied] '
        'Missing or insufficient permissions.',
      );

      await controller.load(uid);

      expect(controller.isLoading, isFalse,
          reason: 'the spinner must always be reset');
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, contains('permission'));
      expect(controller.preferences, const DietExercisePreferences(),
          reason: 'defaults are used when the read fails');
      expect(controller.dietPlan.meals, isNotEmpty);
      expect(controller.dailyRoutine, isNotEmpty);
      expect(controller.hydration.date, today());
    });

    test('a network failure keeps the module usable and is classified',
        () async {
      dietService.failure = Exception('[firebase_firestore/unavailable] '
          'Unable to resolve host "firestore.googleapis.com"');

      await controller.load(uid);

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, contains('internet connection'));
      expect(controller.preferences, const DietExercisePreferences());
      expect(controller.dietPlan.meals, isNotEmpty);
      expect(controller.exerciseCatalog, isNotEmpty);
    });

    test('a hung preference read times out instead of spinning forever',
        () async {
      final originalTimeout = DietExerciseController.loadTimeout;
      DietExerciseController.loadTimeout = const Duration(milliseconds: 50);
      addTearDown(() => DietExerciseController.loadTimeout = originalTimeout);

      dietService.hang = true;

      await controller.load(uid);

      expect(controller.isLoading, isFalse,
          reason: 'the timeout must reset the loading flag');
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, contains('too long'));
      expect(controller.preferences, const DietExercisePreferences());
      expect(controller.dietPlan.meals, isNotEmpty);
      expect(controller.dailyRoutine, isNotEmpty);
    });

    test('a retry after a failed preference load picks up the saved values',
        () async {
      dietService.failure = Exception(
        '[firebase_firestore/permission-denied] denied',
      );
      await controller.load(uid);
      expect(controller.hasError, isTrue);
      expect(controller.preferences, const DietExercisePreferences());

      // Firestore becomes reachable again and the document was there all along.
      dietService.failure = null;
      dietService.stored = const DietExercisePreferences(
        goal: WellnessGoal.healthyRoutine,
        foodPreference: FoodPreference.vegan,
        hasSelectedGoal: true,
      );

      await controller.refresh();

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse, reason: 'the retry clears the banner');
      expect(controller.preferences.goal, WellnessGoal.healthyRoutine);
      expect(controller.preferences.foodPreference, FoodPreference.vegan);
      expect(controller.preferences.hasSelectedGoal, isTrue);
    });

    test('every slice failing still resets the loading flag', () async {
      dietService.shouldThrow = true;
      exerciseService.shouldThrow = true;
      activityService.shouldThrow = true;

      await controller.load(uid);

      expect(controller.isLoading, isFalse);
      expect(controller.isHistoryLoading, isFalse);
      expect(controller.isSaving, isFalse);
    });
  });

  group('Missing authentication', () {
    test('the services refuse an empty user id before touching Firestore', () async {
      expect(
        () => DietService().loadPreferences(''),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => ExerciseService().loadWorkout('', '2026-02-10'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => ActivityTrackingService().loadHydration('', '2026-02-10'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => ActivityTrackingService().saveActivity(
              '',
              const DailyActivity(date: '2026-02-10'),
            ),
        throwsA(isA<AuthException>()),
      );
    });

    test('a signed-out load does not mark the controller as signed in', () async {
      await controller.load('');

      expect(controller.isSignedIn, isFalse);
      expect(controller.date, today());
    });
  });

  group('Firestore ownership', () {
    test('load uses the authenticated uid for every user-scoped read',
        () async {
      await controller.load('firebase-uid-123');

      expect(dietService.lastUserId, 'firebase-uid-123');
      expect(exerciseService.lastUserId, 'firebase-uid-123');
      expect(activityService.lastUserId, 'firebase-uid-123');
    });

    test('saving preferences keeps using the authenticated uid', () async {
      await controller.load('firebase-uid-123');

      final saved = await controller.savePreferences(
        'firebase-uid-123',
        const DietExercisePreferences(
          goal: WellnessGoal.healthyRoutine,
          hasSelectedGoal: true,
        ),
      );

      expect(saved, isTrue);
      expect(dietService.lastUserId, 'firebase-uid-123');
      expect(dietService.saveCount, 1);
      expect(controller.hasError, isFalse,
          reason: 'an owner-allowed write is not a permission error');
    });

    test('an authenticated load produces no permission error', () async {
      await controller.load('firebase-uid-123');

      expect(controller.hasError, isFalse);
    });
  });

  group('Water counter', () {
    test('incrementing persists the new count', () async {
      await controller.load(uid);

      expect(await controller.incrementWater(uid), isTrue);
      expect(controller.waterGlasses, 1);
      expect(activityService.hydration[today()]!.glasses, 1);

      expect(await controller.incrementWater(uid), isTrue);
      expect(controller.waterGlasses, 2);
      expect(activityService.hydration[today()]!.glasses, 2);
    });

    test('decrementing stops at zero instead of going negative', () async {
      await controller.load(uid);

      expect(await controller.decrementWater(uid), isFalse);
      expect(controller.waterGlasses, 0);
      expect(activityService.hydration, isEmpty, reason: 'no pointless write');

      await controller.incrementWater(uid);
      expect(await controller.decrementWater(uid), isTrue);
      expect(controller.waterGlasses, 0);
      expect(await controller.decrementWater(uid), isFalse);
      expect(controller.waterGlasses, 0);
    });

    test('water progress reflects the user goal', () async {
      await controller.load(uid);
      for (var i = 0; i < 4; i++) {
        await controller.incrementWater(uid);
      }

      expect(controller.waterProgress, 0.5);
      expect(controller.waterGoalReached, isFalse);
      expect(controller.todaySummary.waterGlasses, 4);
    });

    test('changing the water goal updates the counter and both documents', () async {
      await controller.load(uid);

      expect(await controller.setWaterGoal(uid, 10), isTrue);

      expect(controller.waterGoal, 10);
      expect(controller.preferences.waterGoal, 10);
      expect(activityService.hydration[today()]!.goal, 10);
      expect(dietService.stored.waterGoal, 10);
    });

    test('the stored water goal is applied when the day has no document yet', () async {
      dietService = FakeDietService(
        preferences: const DietExercisePreferences(waterGoal: 12),
      );
      controller = DietExerciseController(
        dietService: dietService,
        exerciseService: exerciseService,
        activityService: activityService,
      );

      await controller.load(uid);

      expect(controller.waterGoal, 12);
    });

    test('an unchanged goal is not written again', () async {
      await controller.load(uid);

      expect(await controller.setWaterGoal(uid, HydrationRecord.defaultGoal), isFalse);
    });
  });

  group('Exercise completion', () {
    test('completing an exercise adds its minutes and persists once', () async {
      await controller.load(uid);
      final exercise = controller.exerciseCatalog.first;

      expect(await controller.toggleExercise(uid, exercise), isTrue);
      expect(controller.isExerciseCompleted(exercise.id), isTrue);
      expect(controller.exerciseMinutes, exercise.durationMinutes);

      expect(await controller.toggleExercise(uid, exercise), isTrue);
      expect(controller.isExerciseCompleted(exercise.id), isFalse);
      expect(controller.exerciseMinutes, 0);
      expect(exerciseService.workouts[today()]!.completedCount, 0);
    });

    test('toggling twice never double counts minutes', () async {
      await controller.load(uid);
      final exercise = controller.exerciseCatalog.first;

      await controller.toggleExercise(uid, exercise);
      await controller.toggleExercise(uid, exercise);
      await controller.toggleExercise(uid, exercise);

      expect(controller.completedExerciseCount, 1);
      expect(controller.exerciseMinutes, exercise.durationMinutes);
    });

    test('exercise minutes plus manual minutes make up the daily total', () async {
      await controller.load(uid);
      final exercise = controller.exerciseCatalog.first;

      await controller.toggleExercise(uid, exercise);
      await controller.addActivityEntry(uid, name: 'Walk', minutes: 15);

      expect(controller.exerciseMinutes, exercise.durationMinutes + 15);
      expect(controller.manualActivityMinutes, 15);
      expect(controller.todaySummary.exerciseMinutes, exercise.durationMinutes + 15);
    });

    test('exercise progress is measured against the user goal', () async {
      dietService = FakeDietService(
        preferences: const DietExercisePreferences(dailyExerciseGoalMinutes: 10),
      );
      controller = DietExerciseController(
        dietService: dietService,
        exerciseService: exerciseService,
        activityService: activityService,
      );
      await controller.load(uid);
      final exercise = controller.exerciseCatalog.first;

      await controller.toggleExercise(uid, exercise);

      expect(controller.exerciseProgress, 1.0, reason: 'capped at 100%');
      expect(controller.todaySummary.completedExercises, 1);
    });
  });

  group('Manual activity', () {
    test('an entry needs a name and a positive duration', () async {
      await controller.load(uid);

      expect(await controller.addActivityEntry(uid, name: '   ', minutes: 10), isFalse);
      expect(controller.hasError, isTrue);

      expect(await controller.addActivityEntry(uid, name: 'Walk', minutes: 0), isFalse);
      expect(controller.hasError, isTrue);
      expect(controller.activityEntries, isEmpty);
    });

    test('an added entry is trimmed, stored and removable', () async {
      await controller.load(uid);

      expect(await controller.addActivityEntry(uid, name: '  Brisk walk ', minutes: 25), isTrue);

      final entry = controller.activityEntries.single;
      expect(entry.name, 'Brisk walk');
      expect(entry.minutes, 25);
      expect(activityService.activity[today()]!.entryCount, 1);

      expect(await controller.removeActivityEntry(uid, entry.id), isTrue);
      expect(controller.activityEntries, isEmpty);
      expect(activityService.activity[today()]!.entryCount, 0);
    });

    test('removing an unknown entry does nothing', () async {
      await controller.load(uid);

      expect(await controller.removeActivityEntry(uid, 'nope'), isFalse);
    });

    test('steps are stored manually and negatives are rejected', () async {
      await controller.load(uid);

      expect(await controller.logSteps(uid, -10), isFalse);
      expect(controller.hasError, isTrue);
      expect(controller.steps, 0);

      expect(await controller.logSteps(uid, 6400), isTrue);
      expect(controller.steps, 6400);
      expect(activityService.activity[today()]!.steps, 6400);
      expect(controller.todaySummary.steps, 6400);

      expect(await controller.logSteps(uid, 6400), isFalse, reason: 'unchanged');
    });
  });

  group('Preferences', () {
    test('saving marks the goal as chosen and applies the water goal', () async {
      await controller.load(uid);

      final saved = await controller.savePreferences(
        uid,
        const DietExercisePreferences(
          goal: WellnessGoal.weightManagement,
          foodPreference: FoodPreference.vegetarian,
          waterGoal: 9,
          dailyExerciseGoalMinutes: 45,
        ),
      );

      expect(saved, isTrue);
      expect(controller.preferences.hasSelectedGoal, isTrue);
      expect(controller.preferences.goal, WellnessGoal.weightManagement);
      expect(controller.waterGoal, 9);
      expect(dietService.stored.goal, WellnessGoal.weightManagement);
      expect(activityService.hydration[today()]!.goal, 9);
    });

    test('preferences survive a reload', () async {
      await controller.load(uid);
      await controller.savePreferences(
        uid,
        const DietExercisePreferences(goal: WellnessGoal.healthyRoutine),
      );

      final reloaded = DietExerciseController(
        dietService: dietService,
        exerciseService: exerciseService,
        activityService: activityService,
      );
      await reloaded.load(uid);

      expect(reloaded.preferences.goal, WellnessGoal.healthyRoutine);
      expect(reloaded.preferences.hasSelectedGoal, isTrue);
    });
  });

  group('Diet plan generation', () {
    test('the plan covers the day and carries a wellness disclaimer', () async {
      await controller.load(uid);
      final plan = controller.dietPlan;

      expect(plan.meals, isNotEmpty);
      expect(plan.meals.map((meal) => meal.slot).toSet().length, plan.meals.length);
      expect(plan.disclaimer.toLowerCase(), contains('not a substitute'));
      for (final meal in plan.meals) {
        expect(meal.items, isNotEmpty, reason: '${meal.slot} should have foods');
        for (final item in meal.items) {
          expect(item.name, isNotEmpty);
        }
      }
    });

    test('the food preference changes the meals', () async {
      await controller.load(uid);
      final defaultPlan = controller.dietPlan;

      await controller.savePreferences(
        uid,
        const DietExercisePreferences(foodPreference: FoodPreference.vegan),
      );
      final veganPlan = controller.dietPlan;

      expect(veganPlan.meals.length, defaultPlan.meals.length);
      final veganText = veganPlan.meals
          .expand((meal) => meal.items)
          .map((item) => item.name.toLowerCase())
          .join(' ')
          .replaceAll('plant milk', '');
      for (final animal in const [
        'milk',
        'buttermilk',
        'curd',
        'paneer',
        'egg',
        'chicken',
        'fish',
        'meat',
      ]) {
        expect(veganText, isNot(contains(animal)),
            reason: 'vegan plans must not suggest $animal');
      }
      expect(veganPlan.personalizationNotes.join(' '),
          contains(FoodPreference.vegan.label));
    });

    test('profile data is used for personalization when available', () async {
      await controller.load(uid);
      controller.setProfile(const UserProfile(
        uid: uid,
        fullName: 'Asha',
        email: 'asha@example.com',
        allergies: 'Peanuts',
      ));

      final notes = controller.dietPlan.personalizationNotes.join(' ');

      expect(notes.toLowerCase(), contains('peanut'));
    });

    test('personalization notes stay general when the profile is missing', () async {
      await controller.load(uid);

      expect(controller.profile, isNull);
      final notes = controller.dietPlan.personalizationNotes.join(' ').toLowerCase();
      expect(notes, contains('profile'));
      expect(notes, isNot(contains('allerg')));
    });
  });

  group('Seven day history', () {
    test('history covers exactly seven days with empty defaults', () async {
      await controller.loadHistory(uid);

      expect(controller.isHistoryLoading, isFalse);
      expect(controller.history, hasLength(7));
      expect(controller.history.first.date, dateKeyOf(DateTime.now().subtract(const Duration(days: 6))));
      expect(controller.history.last.date, dateKeyOf(DateTime.now()));
      for (final day in controller.history) {
        expect(day.exerciseMinutes, 0);
        expect(day.waterGlasses, 0);
      }
    });

    test('stored days are aggregated into the history', () async {
      final yesterday = dateKeyOf(DateTime.now().subtract(const Duration(days: 1)));
      exerciseService.workouts[yesterday] = WorkoutRecord(date: yesterday)
          .markCompleted('walk', 30);
      activityService.hydration[yesterday] =
          HydrationRecord(date: yesterday, glasses: 6, goal: 8);

      await controller.loadHistory(uid);

      final day = controller.history.firstWhere((summary) => summary.date == yesterday);
      expect(day.exerciseMinutes, 30);
      expect(day.completedExercises, 1);
      expect(day.waterGlasses, 6);
    });

    test('a history failure surfaces a message', () async {
      activityService.shouldThrow = true;

      await controller.loadHistory(uid);

      expect(controller.isHistoryLoading, isFalse);
      expect(controller.hasError, isTrue);
    });

    test('history is unmodifiable', () async {
      await controller.loadHistory(uid);

      expect(
        () => controller.history.add(
          const DailyActivitySummary(date: '2026-02-10'),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
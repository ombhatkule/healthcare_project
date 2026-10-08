import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/diet_exercise/models/models.dart';
import 'package:healthcare_app/features/diet_exercise/services/services.dart';

void main() {
  group('DietPlan serialization', () {
    test('keeps meal data through a toMap/fromMap round trip', () {
      const original = DietPlan(
        title: 'Your balanced day',
        subtitle: 'Vegetarian · Lightly active',
        disclaimer: 'General guidance only.',
        personalizationNotes: <String>['Portion-aware meals'],
        nutritionTips: <String>['Add a glass of water'],
        meals: <Meal>[
          Meal(
            slot: MealSlot.breakfast,
            title: 'Breakfast',
            tip: 'Start the day steady.',
            items: <MealItem>[
              MealItem(
                name: 'Oatmeal with banana',
                serving: '1 bowl',
                approximateCalories: 250,
                nutritionNote: 'Whole grain, fibre rich',
              ),
              MealItem(name: 'Warm water', serving: '1 glass'),
            ],
          ),
          Meal(slot: MealSlot.lunch, title: 'Lunch'),
        ],
      );

      final restored = DietPlan.fromMap(original.toMap());

      expect(restored.title, original.title);
      expect(restored.subtitle, original.subtitle);
      expect(restored.disclaimer, original.disclaimer);
      expect(restored.personalizationNotes, original.personalizationNotes);
      expect(restored.nutritionTips, original.nutritionTips);
      expect(restored.meals, hasLength(2));
      expect(restored.meals.first.slot, MealSlot.breakfast);
      expect(restored.meals.first.items, hasLength(2));
      expect(restored.meals.first.items.first.name, 'Oatmeal with banana');
      expect(restored.meals.first.items.first.approximateCalories, 250);
      expect(restored.meals.first.tip, 'Start the day steady.');
      expect(restored.headlineMeal, restored.meals.first);
      expect(restored.approximateCalories, 250);
    });

    test('malformed plan data falls back instead of throwing', () {
      final restored = DietPlan.fromMap(<String, dynamic>{
        'title': 42,
        'meals': 'not-a-list',
      });

      expect(restored.title, '');
      expect(restored.meals, isEmpty);
      expect(restored.headlineMeal, isNull);
      expect(restored.approximateCalories, isNull);
      expect(restored.isEmpty, isTrue);
    });

    test('meal calories are summed only when every item has a figure', () {
      const withCalories = Meal(
        slot: MealSlot.dinner,
        title: 'Dinner',
        items: <MealItem>[
          MealItem(name: 'Paneer', approximateCalories: 200),
          MealItem(name: 'Rice', approximateCalories: 180),
        ],
      );
      const withoutCalories = Meal(
        slot: MealSlot.dinner,
        title: 'Dinner',
        items: <MealItem>[MealItem(name: 'Soup')],
      );

      expect(withCalories.approximateCalories, 380);
      expect(withoutCalories.approximateCalories, isNull);
    });

    test('unknown meal slots degrade to a known slot', () {
      final meal = Meal.fromMap(<String, dynamic>{
        'slot': 'midnightSnack',
        'title': 'Odd meal',
      });

      expect(meal.slot, MealSlot.breakfast);
    });
  });

  group('Exercise serialization', () {
    const exercise = ExerciseItem(
      id: 'cat-cow',
      name: 'Cat-Cow Stretch',
      category: ExerciseCategory.mobility,
      durationMinutes: 5,
      difficulty: ExerciseDifficulty.beginner,
      description: 'Gentle warm-up for the spine.',
      instructions: 'Move slowly with the breath.',
      safetyNote: 'Stop if you feel sharp pain.',
      steps: <String>['On hands and knees', 'Inhale, arch the back'],
    );

    test('keeps exercise data through a toMap/fromMap round trip', () {
      final restored = ExerciseItem.fromMap(exercise.toMap());

      expect(restored.id, exercise.id);
      expect(restored.name, exercise.name);
      expect(restored.category, ExerciseCategory.mobility);
      expect(restored.difficulty, ExerciseDifficulty.beginner);
      expect(restored.durationMinutes, 5);
      expect(restored.description, exercise.description);
      expect(restored.instructions, exercise.instructions);
      expect(restored.safetyNote, exercise.safetyNote);
      expect(restored.steps, <String>['On hands and knees', 'Inhale, arch the back']);
      expect(restored.summaryLabel, '5 min · Beginner');
    });

    test('malformed exercise data falls back instead of throwing', () {
      final restored = ExerciseItem.fromMap(<String, dynamic>{
        'id': 'broken',
        'name': 5,
        'category': 'not-a-category',
        'difficulty': 'not-a-difficulty',
        'durationMinutes': -3,
        'steps': 'nope',
      });

      expect(restored.name, '');
      expect(restored.category, ExerciseCategory.walking);
      expect(restored.difficulty, ExerciseDifficulty.beginner);
      expect(restored.durationMinutes, greaterThan(0));
      expect(restored.steps, isEmpty);
    });

    test('catalog items always carry a safety note and instructions', () {
      expect(ExerciseService.catalog, isNotEmpty);
      for (final item in ExerciseService.catalog) {
        expect(item.safetyNote, isNotEmpty,
            reason: '${item.name} must carry a safety note');
        expect(item.instructions, isNotEmpty,
            reason: '${item.name} must carry instructions');
        expect(item.description, isNotEmpty,
            reason: '${item.name} must carry a description');
        expect(item.durationMinutes, greaterThan(0));
      }
    });
  });

  group('HydrationRecord (water counter)', () {
    test('increment adds exactly one glass', () {
      const record = HydrationRecord(date: '2026-02-10', glasses: 3);
      final updated = record.increment();

      expect(updated.glasses, 4);
      expect(updated.date, '2026-02-10');
    });

    test('decrement removes exactly one glass', () {
      const record = HydrationRecord(date: '2026-02-10', glasses: 3);
      expect(record.decrement().glasses, 2);
    });

    test('water can never become negative', () {
      const record = HydrationRecord(date: '2026-02-10', glasses: 0);

      expect(record.decrement().glasses, 0);
      expect(record.copyWith(glasses: -5).glasses, 0);
      expect(
        HydrationRecord.fromMap('2026-02-10', <String, dynamic>{'glasses': -2}).glasses,
        0,
      );
    });

    test('round trips through toMap/fromMap', () {
      final original = const HydrationRecord(date: '2026-02-10', glasses: 5, goal: 10);
      final restored = HydrationRecord.fromMap('2026-02-10', original.toMap());

      expect(restored.glasses, 5);
      expect(restored.goal, 10);
    });

    test('goal is clamped and progress is safe when the goal is zero', () {
      const record = HydrationRecord(date: '2026-02-10', glasses: 4, goal: 8);

      expect(record.withGoal(1).goal, HydrationRecord.minGoal);
      expect(record.withGoal(99).goal, HydrationRecord.maxGoal);
      expect(record.progress, 0.5);
      expect(
        const HydrationRecord(date: 'd', glasses: 4, goal: 2).progress,
        1.0,
      );
      expect(const HydrationRecord(date: 'd', glasses: 4, goal: 0).progress, 0);
      expect(const HydrationRecord(date: 'd', glasses: 4, goal: 0).goalReached, isFalse);
    });

    test('goalReached only once the user goal is met', () {
      expect(const HydrationRecord(date: 'd', glasses: 7, goal: 8).goalReached, isFalse);
      expect(const HydrationRecord(date: 'd', glasses: 8, goal: 8).goalReached, isTrue);
    });
  });

  group('WorkoutRecord (exercise completion)', () {
    const catalog = <ExerciseItem>[
      ExerciseItem(
        id: 'walk',
        name: 'Brisk walk',
        category: ExerciseCategory.cardio,
        durationMinutes: 20,
        difficulty: ExerciseDifficulty.beginner,
        description: '',
        instructions: '',
        safetyNote: '',
      ),
      ExerciseItem(
        id: 'stretch',
        name: 'Stretch',
        category: ExerciseCategory.mobility,
        durationMinutes: 10,
        difficulty: ExerciseDifficulty.beginner,
        description: '',
        instructions: '',
        safetyNote: '',
      ),
    ];

    test('marking an exercise completed adds it once and adds its minutes', () {
      final record = const WorkoutRecord(date: '2026-02-10')
          .markCompleted('walk', catalog.first.durationMinutes);

      expect(record.isCompleted('walk'), isTrue);
      expect(record.completedCount, 1);
      expect(record.minutes, 20);
    });

    test('re-completing the same exercise never duplicates minutes', () {
      var record = const WorkoutRecord(date: '2026-02-10')
          .markCompleted('walk', catalog.first.durationMinutes);
      record = record.markCompleted('walk', catalog.first.durationMinutes);
      record = record.markCompleted('walk', catalog.first.durationMinutes);

      expect(record.completedCount, 1);
      expect(record.minutes, 20);
    });

    test('blank exercise ids are ignored', () {
      final record = const WorkoutRecord(date: '2026-02-10').markCompleted('  ', 30);

      expect(record.completedCount, 0);
      expect(record.minutes, 0);
    });

    test('un-marking keeps the minute total consistent with the catalog', () {
      var record = const WorkoutRecord(date: '2026-02-10')
          .markCompleted('walk', catalog[0].durationMinutes)
          .markCompleted('stretch', catalog[1].durationMinutes);
      expect(record.minutes, 30);

      record = record.markNotCompleted('walk', catalog);

      expect(record.isCompleted('walk'), isFalse);
      expect(record.completedCount, 1);
      expect(record.minutes, 10);
    });

    test('un-marking an exercise that was never completed changes nothing', () {
      final record = const WorkoutRecord(date: '2026-02-10');
      expect(record.markNotCompleted('walk', catalog).minutes, 0);
      expect(record.markNotCompleted('walk', catalog).completedCount, 0);
    });

    test('round trips through toMap/fromMap and ignores malformed ids', () {
      final original = const WorkoutRecord(date: '2026-02-10')
          .markCompleted('walk', 20);
      final restored = WorkoutRecord.fromMap('2026-02-10', original.toMap());

      expect(restored.completedExerciseIds, {'walk'});
      expect(restored.minutes, 20);

      final messy = WorkoutRecord.fromMap('2026-02-10', <String, dynamic>{
        'completedExerciseIds': <dynamic>['walk', '', '  ', 5],
        'minutes': 'abc',
      });
      expect(messy.completedExerciseIds, {'walk'});
      expect(messy.minutes, 0);
    });

    test('timestamps are parsed from Firestore values', () {
      final now = DateTime(2026, 2, 10, 8);
      final restored = WorkoutRecord.fromMap('2026-02-10', <String, dynamic>{
        'updatedAt': Timestamp.fromDate(now),
      });

      expect(restored.updatedAt, now);
    });
  });

  group('DailyActivity (daily activity calculation)', () {
    test('daily total adds completed exercises and manual entries', () {
      final workout = const WorkoutRecord(date: '2026-02-10')
          .markCompleted('walk', 20);
      final activity = const DailyActivity(date: '2026-02-10', steps: 4200)
          .addEntry(const ActivityEntry(id: 'a1', name: 'Housework', minutes: 25))
          .addEntry(const ActivityEntry(id: 'a2', name: 'Stairs', minutes: 10));

      final summary = DailyActivitySummary.fromParts(
        date: '2026-02-10',
        hydration: const HydrationRecord(date: '2026-02-10', glasses: 5, goal: 8),
        workout: workout,
        activity: activity,
      );

      expect(summary.exerciseMinutes, 55);
      expect(summary.completedExercises, 1);
      expect(summary.waterGlasses, 5);
      expect(summary.waterGoal, 8);
      expect(summary.steps, 4200);
      expect(summary.waterProgress, closeTo(0.625, 0.001));
      expect(summary.hasAnyActivity, isTrue);
    });

    test('manual minutes never go negative and negative entries are stored as zero', () {
      final activity = const DailyActivity(date: '2026-02-10')
          .addEntry(const ActivityEntry(id: 'a1', name: 'Walk', minutes: -20));

      expect(activity.entries.single.minutes, 0);
      expect(activity.manualMinutes, 0);
    });

    test('entries can be removed and missing ids are ignored', () {
      final activity = const DailyActivity(date: '2026-02-10')
          .addEntry(const ActivityEntry(id: 'a1', name: 'Walk', minutes: 10));

      expect(activity.removeEntry('nope'), same(activity));
      final updated = activity.removeEntry('a1');
      expect(updated.entries, isEmpty);
      expect(updated.isEmpty, isTrue);
    });

    test('steps cannot go negative', () {
      expect(const DailyActivity(date: 'd', steps: 10).copyWith(steps: -4).steps, 0);
      expect(
        DailyActivity.fromMap('d', <String, dynamic>{'steps': -100}).steps,
        0,
      );
    });

    test('round trips entries through toMap/fromMap', () {
      final original = const DailyActivity(date: '2026-02-10', steps: 1500)
          .addEntry(const ActivityEntry(id: 'a1', name: 'Walk', minutes: 30));
      final restored = DailyActivity.fromMap('2026-02-10', original.toMap());

      expect(restored.steps, 1500);
      expect(restored.entryCount, 1);
      expect(restored.entries.single.name, 'Walk');
      expect(restored.entries.single.minutes, 30);
    });

    test('malformed activity data falls back instead of throwing', () {
      final restored = DailyActivity.fromMap('2026-02-10', <String, dynamic>{
        'steps': 'many',
        'entries': <dynamic>['not-a-map', 7, <String, dynamic>{'name': 'Walk', 'minutes': 12}],
      });

      expect(restored.steps, 0);
      expect(restored.entryCount, 1);
      expect(restored.entries.single.minutes, 12);
    });

    test('an empty day reports no activity and zero water progress', () {
      const summary = DailyActivitySummary(date: '2026-02-10');

      expect(summary.hasAnyActivity, isFalse);
      expect(summary.waterProgress, 0);
      expect(summary.exerciseMinutes, 0);
    });
  });

  group('DietExercisePreferences', () {
    test('defaults are usable with no stored data', () {
      const preferences = DietExercisePreferences();

      expect(preferences.goal, WellnessGoal.generalFitness);
      expect(preferences.foodPreference, FoodPreference.balanced);
      expect(preferences.waterGoal, HydrationRecord.defaultGoal);
      expect(preferences.hasSelectedGoal, isFalse);
      expect(preferences.activityLevelLabel, WellnessActivityLevel.fallbackLabel);
    });

    test('round trips and clamps out-of-range values', () {
      final original = const DietExercisePreferences(
        goal: WellnessGoal.improveFlexibility,
        foodPreference: FoodPreference.vegan,
        activityLevel: WellnessActivityLevel.light,
        waterGoal: 10,
        dailyExerciseGoalMinutes: 45,
        hasSelectedGoal: true,
      );
      final restored = DietExercisePreferences.fromMap(original.toMap());

      expect(restored.goal, WellnessGoal.improveFlexibility);
      expect(restored.foodPreference, FoodPreference.vegan);
      expect(restored.activityLevel, WellnessActivityLevel.light);
      expect(restored.waterGoal, 10);
      expect(restored.dailyExerciseGoalMinutes, 45);
      expect(restored.hasSelectedGoal, isTrue);

      final clamped = DietExercisePreferences.fromMap(<String, dynamic>{
        'waterGoal': 999,
        'dailyExerciseGoalMinutes': 1,
        'goal': 'somethingElse',
        'foodPreference': 'somethingElse',
        'activityLevel': 'somethingElse',
      });
      expect(clamped.waterGoal, HydrationRecord.maxGoal);
      expect(
        clamped.dailyExerciseGoalMinutes,
        DietExercisePreferences.minExerciseGoalMinutes,
      );
      expect(clamped.goal, WellnessGoal.generalFitness);
      expect(clamped.foodPreference, FoodPreference.balanced);
      expect(clamped.activityLevel, WellnessActivityLevel.moderate);
    });

    test('a malformed document falls back to defaults instead of throwing',
        () {
      // Wrong types in every field, exactly what an older build or a
      // hand-edited document can leave behind. The previous implementation
      // cast these with `as String?` and threw a TypeError, which bubbled up
      // as a load failure for an optional preference.
      final recovered = DietExercisePreferences.fromMap(<String, dynamic>{
        'goal': 42,
        'foodPreference': true,
        'activityLevel': ['moderate'],
        'waterGoal': 'twelve',
        'dailyExerciseGoalMinutes': null,
        'hasSelectedGoal': 'yes',
        'updatedAt': 'not a timestamp',
      });

      expect(recovered.goal, WellnessGoal.generalFitness);
      expect(recovered.foodPreference, FoodPreference.balanced);
      expect(recovered.activityLevel, WellnessActivityLevel.moderate);
      expect(recovered.waterGoal, HydrationRecord.defaultGoal);
      expect(
        recovered.dailyExerciseGoalMinutes,
        DietExercisePreferences.defaultExerciseGoalMinutes,
      );
      expect(recovered.hasSelectedGoal, isFalse);
      expect(recovered.updatedAt, isNull);
      expect(recovered.activityLevelLabel, WellnessActivityLevel.fallbackLabel);
    });

    test('an empty document produces the same defaults as no document', () {
      final fromEmptyMap = DietExercisePreferences.fromMap(const {});

      expect(fromEmptyMap.goal, const DietExercisePreferences().goal);
      expect(fromEmptyMap.waterGoal, const DietExercisePreferences().waterGoal);
      expect(fromEmptyMap.hasSelectedGoal, isFalse);
    });
  });

  group('dateKeyOf', () {
    test('formats a date as yyyy-MM-dd', () {
      expect(dateKeyOf(DateTime(2026, 2, 3)), '2026-02-03');
      expect(dateKeyOf(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('produces a unique key per day', () {
      final first = dateKeyOf(DateTime(2026, 2, 3, 1));
      final later = dateKeyOf(DateTime(2026, 2, 3, 23, 59));

      expect(first, later);
      expect(first, isNot(dateKeyOf(DateTime(2026, 2, 4))));
    });
  });
}
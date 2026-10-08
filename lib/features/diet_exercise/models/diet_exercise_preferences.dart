import 'package:cloud_firestore/cloud_firestore.dart';

import 'hydration_model.dart';

/// The wellness goal a user is currently working towards.
///
/// These are habit goals only — no goal here is presented as a treatment.
enum WellnessGoal {
  generalFitness('General fitness', 'Balanced everyday wellness'),
  weightManagement('Weight management', 'Portion-aware balanced meals'),
  improveActivity('Improve activity', 'Gradually more daily movement'),
  improveFlexibility('Improve flexibility', 'Mobility and stretching focus'),
  healthyRoutine('Build healthy routine', 'Consistent meal and water habits');

  const WellnessGoal(this.label, this.description);

  final String label;
  final String description;

  String get key => name;

  static WellnessGoal fromKey(String? key) {
    for (final goal in WellnessGoal.values) {
      if (goal.key == key) return goal;
    }
    return WellnessGoal.generalFitness;
  }
}

/// Food preference used to pick realistic meal examples.
///
/// [FoodPreference.balanced] is the default so the module is fully usable
/// before the user shares anything.
enum FoodPreference {
  balanced('Balanced meal options', 'Vegetarian and non-vegetarian choices'),
  vegetarian('Vegetarian', 'No meat or fish'),
  nonVegetarian('Non-vegetarian', 'Includes meat or fish options'),
  vegan('Vegan', 'No animal products');

  const FoodPreference(this.label, this.description);

  final String label;
  final String description;

  String get key => name;

  static FoodPreference fromKey(String? key) {
    for (final preference in FoodPreference.values) {
      if (preference.key == key) return preference;
    }
    return FoodPreference.balanced;
  }
}

/// Self-reported general activity level, used only to scale suggestions.
enum WellnessActivityLevel {
  sedentary('Mostly seated', 'Little movement during the day'),
  light('Lightly active', 'Some walking or light movement'),
  moderate('Moderately active', 'Regular movement most days'),
  active('Very active', 'Physical work or daily training');

  const WellnessActivityLevel(this.label, this.description);

  final String label;
  final String description;

  String get key => name;

  static WellnessActivityLevel fromKey(String? key) {
    for (final level in WellnessActivityLevel.values) {
      if (level.key == key) return level;
    }
    return WellnessActivityLevel.moderate;
  }

  /// Label shown when the user has not chosen a level.
  static const String fallbackLabel = 'General Activity';
}

/// User-selected wellness preferences stored at
/// `users/{uid}/diet_exercise_preferences/preferences`.
///
/// Defaults keep the module usable with no stored data at all.
class DietExercisePreferences {
  final WellnessGoal goal;
  final FoodPreference foodPreference;
  final WellnessActivityLevel activityLevel;
  final int waterGoal;
  final int dailyExerciseGoalMinutes;
  final bool hasSelectedGoal;
  final DateTime? updatedAt;

  static const int defaultExerciseGoalMinutes = 30;
  static const int minExerciseGoalMinutes = 10;
  static const int maxExerciseGoalMinutes = 90;

  const DietExercisePreferences({
    this.goal = WellnessGoal.generalFitness,
    this.foodPreference = FoodPreference.balanced,
    this.activityLevel = WellnessActivityLevel.moderate,
    this.waterGoal = HydrationRecord.defaultGoal,
    this.dailyExerciseGoalMinutes = defaultExerciseGoalMinutes,
    this.hasSelectedGoal = false,
    this.updatedAt,
  });

  factory DietExercisePreferences.fromMap(Map<String, dynamic> map) {
    final rawExerciseGoal = map['dailyExerciseGoalMinutes'];
    final exerciseGoal = rawExerciseGoal is num && rawExerciseGoal > 0
        ? rawExerciseGoal.round()
        : defaultExerciseGoalMinutes;
    final rawWaterGoal = map['waterGoal'];
    final waterGoal = rawWaterGoal is num && rawWaterGoal > 0
        ? rawWaterGoal.round()
        : HydrationRecord.defaultGoal;
    return DietExercisePreferences(
      // Every field is type-checked first: a document written by an older
      // build (or with an unexpected type) must fall back to the default
      // instead of throwing a cast error and failing the whole module.
      goal: WellnessGoal.fromKey(_optionalString(map['goal'])),
      foodPreference: FoodPreference.fromKey(_optionalString(map['foodPreference'])),
      activityLevel:
          WellnessActivityLevel.fromKey(_optionalString(map['activityLevel'])),
      waterGoal:
          waterGoal.clamp(HydrationRecord.minGoal, HydrationRecord.maxGoal),
      dailyExerciseGoalMinutes: exerciseGoal.clamp(
        minExerciseGoalMinutes,
        maxExerciseGoalMinutes,
      ),
      hasSelectedGoal: map['hasSelectedGoal'] == true,
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  /// Returns [value] only when it really is a string, so a malformed stored
  /// value can never escape the safe default path.
  static String? _optionalString(dynamic value) =>
      value is String ? value : null;

  Map<String, dynamic> toMap({bool includeTimestamps = false}) => {
        'goal': goal.key,
        'foodPreference': foodPreference.key,
        'activityLevel': activityLevel.key,
        'waterGoal': waterGoal,
        'dailyExerciseGoalMinutes': dailyExerciseGoalMinutes,
        'hasSelectedGoal': hasSelectedGoal,
        if (includeTimestamps) 'updatedAt': Timestamp.now(),
      };

  DietExercisePreferences copyWith({
    WellnessGoal? goal,
    FoodPreference? foodPreference,
    WellnessActivityLevel? activityLevel,
    int? waterGoal,
    int? dailyExerciseGoalMinutes,
    bool? hasSelectedGoal,
    DateTime? updatedAt,
  }) {
    return DietExercisePreferences(
      goal: goal ?? this.goal,
      foodPreference: foodPreference ?? this.foodPreference,
      activityLevel: activityLevel ?? this.activityLevel,
      waterGoal: waterGoal == null
          ? this.waterGoal
          : waterGoal.clamp(HydrationRecord.minGoal, HydrationRecord.maxGoal),
      dailyExerciseGoalMinutes: dailyExerciseGoalMinutes == null
          ? this.dailyExerciseGoalMinutes
          : dailyExerciseGoalMinutes.clamp(
              minExerciseGoalMinutes,
              maxExerciseGoalMinutes,
            ),
      hasSelectedGoal: hasSelectedGoal ?? this.hasSelectedGoal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Activity level label, falling back to neutral wording when the user has
  /// not chosen one.
  String get activityLevelLabel => hasSelectedGoal
      ? activityLevel.label
      : WellnessActivityLevel.fallbackLabel;

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
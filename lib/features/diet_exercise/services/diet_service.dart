import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../profile/models/user_profile.dart';
import '../models/models.dart';
import 'firestore_operation.dart';

/// Builds diet plans and reads/writes wellness preferences.
///
/// Content lives in Firestore at `users/{userId}/diet_exercise_preferences/
/// preferences` — the same per-user collection shape the rest of the app
/// already uses (for example `medical_profile`), so every user only ever
/// reaches their own document.
class DietService {
  final FirebaseFirestore? _injectedFirestore;

  DietService({FirebaseFirestore? firestore}) : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  /// Firestore path of a user's wellness preferences document.
  ///
  /// Matches the `match /users/{userId}/diet_exercise_preferences/{docId}`
  /// rule and is always built from the authenticated UID passed in.
  static String preferencesDocPath(String userId) =>
      'users/$userId/diet_exercise_preferences/preferences';

  DocumentReference<Map<String, dynamic>> _preferencesDoc(String userId) =>
      _firestore.doc(preferencesDocPath(userId));

  /// Loads the stored preferences, returning safe defaults when the document is
  /// missing or malformed so the module always renders something useful.
  ///
  /// Three outcomes are deliberately treated as success-with-defaults rather
  /// than as an error:
  ///   * the document does not exist yet (a brand new user),
  ///   * the document is empty,
  ///   * the document cannot be parsed (wrong types, older build).
  /// Anything else (permission, network, timeout) is classified by
  /// [runFirestoreOperation] and reported to the controller, which shows it as
  /// a non-blocking banner instead of failing the screen.
  Future<DietExercisePreferences> loadPreferences(String userId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot = await runFirestoreOperation(
        operation: () => _preferencesDoc(userId).get(),
        failureMessage: AppStrings.preferencesLoadFailed,
      );
      if (!snapshot.exists) {
        return const DietExercisePreferences();
      }
      final data = snapshot.data();
      if (data == null || data.isEmpty) {
        return const DietExercisePreferences();
      }
      try {
        return DietExercisePreferences.fromMap(data);
      } catch (_) {
        // Malformed stored document: keep the module usable and log a
        // warning that carries no document contents.
        debugPrint(
          'Stored wellness preferences were unreadable - using defaults.',
        );
        return const DietExercisePreferences();
      }
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(message: AppStrings.preferencesLoadFailed);
    }
  }

  /// Persists the wellness preferences for [userId].
  Future<void> savePreferences(
      String userId, DietExercisePreferences preferences) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      await runFirestoreOperation<void>(
        operation: () => _preferencesDoc(userId).set(
              preferences.toMap(includeTimestamps: true),
              SetOptions(merge: true),
            ),
        failureMessage:
            'Unable to save your diet preferences. Please try again.',
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Unable to save your diet preferences. Please try again.',
      );
    }
  }

  /// Builds today's plan from the selected preferences and whatever profile
  /// information happens to be available.
  ///
  /// A missing profile is never fatal: generic guidance is returned instead.
  DietPlan buildDietPlan({
    DietExercisePreferences preferences = const DietExercisePreferences(),
    UserProfile? profile,
  }) {
    final notes = personalizationNotes(preferences: preferences, profile: profile);
    final meals = _mealsFor(preferences.foodPreference);
    return DietPlan(
      title: "Today's Diet Plan",
      subtitle: 'Example ${preferences.foodPreference.label.toLowerCase()} • '
          'general wellness guidance',
      meals: meals,
      nutritionTips: nutritionTips(preferences.goal),
      personalizationNotes: notes,
      disclaimer: AppStrings.dietPlanDisclaimer,
    );
  }

  /// Short notes describing which inputs shaped the plan and what is missing.
  List<String> personalizationNotes({
    required DietExercisePreferences preferences,
    UserProfile? profile,
  }) {
    final notes = <String>[];

    if (preferences.hasSelectedGoal) {
      notes.add('Wellness goal: ${preferences.goal.label}.');
    } else {
      notes.add(
          'No wellness goal selected yet — showing general guidance you can adjust.');
    }

    notes.add('Food preference: ${preferences.foodPreference.label}.');
    notes.add('Activity level: ${preferences.activityLevelLabel}.');

    if (profile != null) {
      final age = _ageFromProfile(profile);
      if (age != null) {
        notes.add('Age from your profile: about $age years.');
      }
      if (profile.height != null || profile.weight != null) {
        notes.add('Height and weight from your profile were available for context.');
      }
      final allergies = profile.allergies?.trim() ?? '';
      if (allergies.isNotEmpty) {
        notes.add(
          'You have listed allergies ($allergies). Please review every suggested food '
          'with a qualified healthcare professional or registered dietitian.',
        );
      }
    } else {
      notes.add(
          'Add height, weight and activity details in your profile for more tailored suggestions.');
    }

    return notes;
  }

  /// Goal-specific nutrition guidance.
  List<String> nutritionTips(WellnessGoal goal) {
    final common = <String>[
      'Include a source of protein at every main meal (dal, beans, curd, paneer, eggs or fish - pick what suits your diet).',
      'Aim for at least half your plate to be vegetables and salad.',
      'Choose whole grains such as brown rice, whole wheat roti or oats where possible.',
      'Limit sugary drinks and deep-fried snacks; water is the simplest everyday choice.',
    ];
    switch (goal) {
      case WellnessGoal.generalFitness:
        return common;
      case WellnessGoal.weightManagement:
        return [
          'Build meals around vegetables first, then protein, then a measured carbohydrate portion.',
          'Prefer whole fruits over juices to keep fibre intake up.',
          'Keep fried food occasional rather than daily.',
          ...common,
        ];
      case WellnessGoal.improveActivity:
        return [
          'Fuel activity with carbohydrates such as rice, roti, bread or pasta before and after exercise.',
          ...common,
        ];
      case WellnessGoal.improveFlexibility:
        return [...common, 'Add warm water or soup to meals if you notice bloating.'];
      case WellnessGoal.healthyRoutine:
        return [
          'Try to keep meal times roughly consistent each day.',
          'Plan snacks ahead so busy days do not skip meals.',
          ...common,
        ];
    }
  }

  /// Approximate age derived from the profile date of birth, or null.
  int? _ageFromProfile(UserProfile profile) {
    final dob = profile.dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age -= 1;
    }
    return age >= 0 && age < 130 ? age : null;
  }

  /// Builds the five daily meals for a food preference.
  ///
  /// [FoodPreference.balanced] mixes both options, so vegetarian and
  /// non-vegetarian users both see something suitable before choosing. Vegan
  /// plans never suggest an animal product.
  List<Meal> _mealsFor(FoodPreference preference) {
    final balanced = preference == FoodPreference.balanced;
    final vegan = preference == FoodPreference.vegan;
    final vegOnly = vegan ||
        preference == FoodPreference.vegetarian;

    final breakfast = MealItem(
      name: vegan
          ? 'Oats with plant milk and fruit'
          : (balanced
              ? 'Oats with milk and fruit, or eggs with roti'
              : 'Oats with milk and fruit'),
      serving: vegan
          ? '1 bowl oats, 1 glass fortified plant milk, 1 fruit'
          : '1 bowl oats, 1 glass milk or a dairy-free alternative, 1 fruit',
      approximateCalories: 320,
      nutritionNote: 'Whole-grain carbohydrate with protein and fibre.',
    );
    final breakfastExtra = vegan
        ? null
        : (vegOnly
            ? null
            : MealItem(
                name: 'Egg whites (optional protein add-on)',
                serving: '2 whites',
                approximateCalories: 35,
                nutritionNote: 'Lean protein without much fat.',
              ));

    final midMorningDrink = MealItem(
      name: vegan ? 'Coconut water or lemon water' : 'Buttermilk or curd',
      serving: '1 glass',
      approximateCalories: 70,
      nutritionNote: vegan
          ? 'Light hydration without any animal product.'
          : 'Probiotic support and hydration.',
    );

    final lunchProtein = !vegOnly
        ? const MealItem(
            name: 'Grilled chicken or fish (optional)',
            serving: '1 small portion',
            approximateCalories: 140,
            nutritionNote: 'Lean protein; skip if you prefer vegetarian options.',
          )
        : const MealItem(
            name: 'Dal, beans or soy chunks',
            serving: '1 bowl',
            approximateCalories: 160,
            nutritionNote: 'Plant protein, iron and fibre.',
          );

    final dinnerProtein = vegan
        ? const MealItem(
            name: 'Protein source (dal, beans or tofu)',
            serving: '1 bowl',
            approximateCalories: 170,
            nutritionNote: 'Plant protein after the day\'s activity.',
          )
        : (vegOnly
            ? const MealItem(
                name: 'Protein source (paneer, curd or dal)',
                serving: '1 bowl',
                approximateCalories: 180,
                nutritionNote: 'Supports recovery after the day\'s activity.',
              )
            : const MealItem(
                name: 'Protein source (paneer, curd, dal or eggs)',
                serving: '1 bowl / 2 eggs',
                approximateCalories: 180,
                nutritionNote: 'Supports recovery after the day\'s activity.',
              ));

    return [
      Meal(
        slot: MealSlot.breakfast,
        title: 'Breakfast',
        items: [
          breakfast,
          if (breakfastExtra != null) breakfastExtra,
        ],
        tip: 'Starting the day with protein and fibre usually keeps energy steadier.',
      ),
      Meal(
        slot: MealSlot.midMorning,
        title: 'Mid-Morning',
        items: [
          const MealItem(
            name: 'Seasonal fruit with a handful of nuts',
            serving: '1 fruit, 5-6 nuts',
            approximateCalories: 160,
            nutritionNote: 'Natural sugars plus healthy fats and protein.',
          ),
          midMorningDrink,
        ],
        tip: 'A small snack prevents long gaps between meals.',
      ),
      Meal(
        slot: MealSlot.lunch,
        title: 'Lunch',
        items: [
          const MealItem(
            name: 'Rice, roti or bread',
            serving: '1-2 bowls or 2-3 rotis',
            approximateCalories: 220,
            nutritionNote: 'Primary carbohydrate for the meal.',
          ),
          const MealItem(
            name: 'Dal or beans',
            serving: '1 bowl',
            approximateCalories: 150,
            nutritionNote: 'Plant protein, fibre and iron.',
          ),
          const MealItem(
            name: 'Mixed vegetables and salad',
            serving: '1 bowl',
            approximateCalories: 90,
            nutritionNote: 'Vitamins, minerals and fibre.',
          ),
          lunchProtein,
        ],
        tip: 'A plate that is half vegetables generally works well as a default.',
      ),
      Meal(
        slot: MealSlot.eveningSnack,
        title: 'Evening Snack',
        items: const [
          MealItem(
            name: 'Roasted chana, makhana or sprouts',
            serving: '1 small bowl',
            approximateCalories: 120,
            nutritionNote: 'Protein and fibre that keeps you satisfied.',
          ),
          MealItem(
            name: 'Green tea or warm water',
            serving: '1 cup',
            approximateCalories: 5,
            nutritionNote: 'Hydration with a light, low-calorie drink.',
          ),
        ],
        tip: 'Choose one snack rather than several to keep portions simple.',
      ),
      Meal(
        slot: MealSlot.dinner,
        title: 'Dinner',
        items: [
          const MealItem(
            name: 'Vegetables and salad',
            serving: '1 bowl',
            approximateCalories: 80,
            nutritionNote: 'Fibre and micronutrients.',
          ),
          dinnerProtein,
          const MealItem(
            name: 'Roti or rice (smaller portion)',
            serving: '1 roti or half a bowl',
            approximateCalories: 120,
            nutritionNote: 'A lighter carbohydrate portion at night.',
          ),
        ],
        tip: 'Finishing dinner two to three hours before sleep is a common comfort tip.',
      ),
    ];
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import 'meal_model.dart';

/// A complete daily diet plan built for general wellness and education.
///
/// The plan is generated from the user's wellness preferences and whatever
/// profile information is available, and is always labelled as general
/// guidance — never as a prescribed or therapeutic diet.
class DietPlan {
  final String title;
  final String subtitle;
  final List<Meal> meals;
  final List<String> nutritionTips;
  final List<String> personalizationNotes;
  final String disclaimer;

  const DietPlan({
    required this.title,
    this.subtitle = '',
    this.meals = const [],
    this.nutritionTips = const [],
    this.personalizationNotes = const [],
    this.disclaimer = '',
  });

  factory DietPlan.fromMap(Map<String, dynamic> map) {
    return DietPlan(
      title: _text(map['title']),
      subtitle: _text(map['subtitle']),
      meals: _mealList(map['meals']),
      nutritionTips: _stringList(map['nutritionTips']),
      personalizationNotes: _stringList(map['personalizationNotes']),
      disclaimer: _text(map['disclaimer']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'meals': meals.map((meal) => meal.toMap()).toList(),
        'nutritionTips': nutritionTips,
        'personalizationNotes': personalizationNotes,
        if (disclaimer.isNotEmpty) 'disclaimer': disclaimer,
      };

  DietPlan copyWith({
    String? title,
    String? subtitle,
    List<Meal>? meals,
    List<String>? nutritionTips,
    List<String>? personalizationNotes,
    String? disclaimer,
  }) {
    return DietPlan(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      meals: meals ?? this.meals,
      nutritionTips: nutritionTips ?? this.nutritionTips,
      personalizationNotes: personalizationNotes ?? this.personalizationNotes,
      disclaimer: disclaimer ?? this.disclaimer,
    );
  }

  /// Total approximate calories across the day, or `null` when unknown.
  int? get approximateCalories {
    var total = 0;
    var found = false;
    for (final meal in meals) {
      final calories = meal.approximateCalories;
      if (calories != null) {
        total += calories;
        found = true;
      }
    }
    return found ? total : null;
  }

  /// The meal shown on the dashboard summary card.
  Meal? get headlineMeal => meals.isEmpty ? null : meals.first;

  bool get isEmpty => meals.every((meal) => meal.isEmpty);

  static String _text(dynamic value) => value is String ? value : '';

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }

  static List<Meal> _mealList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => Meal.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
  }

  /// Helper used when a plan is written with server timestamps.
  Map<String, dynamic> toMapWithTimestamp() => {
        ...toMap(),
        'updatedAt': Timestamp.now(),
      };
}
/// The five eating occasions covered by a daily plan.
///
/// The order is the display order used by the diet plan screen.
enum MealSlot {
  breakfast('Breakfast', 'Early morning'),
  midMorning('Mid-Morning', 'Late morning'),
  lunch('Lunch', 'Midday'),
  eveningSnack('Evening Snack', 'Late afternoon'),
  dinner('Dinner', 'Evening');

  const MealSlot(this.label, this.hint);

  /// Human readable name, e.g. `Breakfast`.
  final String label;

  /// Short time-of-day hint, e.g. `Early morning`.
  final String hint;

  /// Stable identifier used when persisting to Firestore.
  String get key => name;

  /// Parses a persisted [key]; unknown values fall back to [MealSlot.breakfast]
  /// so malformed data never crashes the screen.
  static MealSlot fromKey(String? key) {
    for (final slot in MealSlot.values) {
      if (slot.key == key) return slot;
    }
    return MealSlot.breakfast;
  }
}

/// A single food inside a [Meal].
///
/// [approximateCalories] is intentionally optional and always presented with
/// "Approximate" wording — it is general wellness information, never a
/// prescribed target.
class MealItem {
  final String name;
  final String serving;
  final int? approximateCalories;
  final String nutritionNote;

  const MealItem({
    required this.name,
    this.serving = '',
    this.approximateCalories,
    this.nutritionNote = '',
  });

  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      name: _readString(map['name']),
      serving: _readString(map['serving']),
      approximateCalories: _readCalories(map['approximateCalories']),
      nutritionNote: _readString(map['nutritionNote']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (serving.isNotEmpty) 'serving': serving,
        if (approximateCalories != null)
          'approximateCalories': approximateCalories,
        if (nutritionNote.isNotEmpty) 'nutritionNote': nutritionNote,
      };

  MealItem copyWith({
    String? name,
    String? serving,
    int? approximateCalories,
    String? nutritionNote,
  }) {
    return MealItem(
      name: name ?? this.name,
      serving: serving ?? this.serving,
      approximateCalories: approximateCalories ?? this.approximateCalories,
      nutritionNote: nutritionNote ?? this.nutritionNote,
    );
  }

  /// True when the item carries an approximate calorie figure.
  bool get hasCalories => approximateCalories != null;

  static int? _readCalories(dynamic value) {
    if (value is num) {
      final rounded = value.round();
      return rounded > 0 ? rounded : null;
    }
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// One eating occasion of a daily plan.
class Meal {
  final MealSlot slot;
  final String title;
  final List<MealItem> items;
  final String tip;

  const Meal({
    required this.slot,
    required this.title,
    this.items = const [],
    this.tip = '',
  });

  factory Meal.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final items = <MealItem>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is Map) {
          items.add(MealItem.fromMap(Map<String, dynamic>.from(entry)));
        }
      }
    }
    return Meal(
      slot: MealSlot.fromKey(_readString(map['slot'])),
      title: _readString(map['title']),
      items: items,
      tip: _readString(map['tip']),
    );
  }

  Map<String, dynamic> toMap() => {
        'slot': slot.key,
        'title': title,
        'items': items.map((item) => item.toMap()).toList(),
        if (tip.isNotEmpty) 'tip': tip,
      };

  Meal copyWith({
    MealSlot? slot,
    String? title,
    List<MealItem>? items,
    String? tip,
  }) {
    return Meal(
      slot: slot ?? this.slot,
      title: title ?? this.title,
      items: items ?? this.items,
      tip: tip ?? this.tip,
    );
  }

  /// Sum of the available approximate calorie figures.
  ///
  /// Returns `null` when no item carries a figure, so the UI can hide the
  /// calorie line entirely instead of showing a misleading `0`.
  int? get approximateCalories {
    var total = 0;
    var found = false;
    for (final item in items) {
      final calories = item.approximateCalories;
      if (calories != null) {
        total += calories;
        found = true;
      }
    }
    return found ? total : null;
  }

  /// The foods on this meal joined into a single line, used by compact cards.
  String get foodSummary => items.map((item) => item.name).join(', ');

  bool get isEmpty => items.isEmpty;
}

/// Defensive string reader shared by the meal models so a malformed Firestore
/// document degrades to empty values instead of throwing.
String _readString(dynamic value) => value is String ? value : '';
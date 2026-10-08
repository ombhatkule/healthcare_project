import 'package:cloud_firestore/cloud_firestore.dart';

/// Water intake for a single day.
///
/// The counter is clamped so it can never go negative and the goal is clamped
/// to a sane range. All values are wellness goals the user can change — they
/// are not medically prescribed amounts.
class HydrationRecord {
  /// Default number of glasses tracked per day.
  static const int defaultGoal = 8;

  /// Smallest configurable goal.
  static const int minGoal = 4;

  /// Largest configurable goal.
  static const int maxGoal = 16;

  final String date;
  final int glasses;
  final int goal;
  final DateTime? updatedAt;

  const HydrationRecord({
    required this.date,
    this.glasses = 0,
    this.goal = defaultGoal,
    this.updatedAt,
  });

  factory HydrationRecord.fromMap(String date, Map<String, dynamic> map) {
    return HydrationRecord(
      date: date,
      glasses: _clampCount(map['glasses'], fallback: 0),
      goal: _clampCount(map['goal'], fallback: defaultGoal).clamp(minGoal, maxGoal),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) => {
        'date': date,
        'glasses': glasses,
        'goal': goal,
        if (includeTimestamps) 'updatedAt': Timestamp.now(),
      };

  HydrationRecord copyWith({int? glasses, int? goal, DateTime? updatedAt}) {
    return HydrationRecord(
      date: date,
      glasses: glasses == null ? this.glasses : glasses < 0 ? 0 : glasses,
      goal: goal == null
          ? this.goal
          : goal.clamp(minGoal, maxGoal),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Adds one glass.
  HydrationRecord increment() => copyWith(glasses: glasses + 1);

  /// Removes one glass, never going below zero.
  HydrationRecord decrement() => copyWith(glasses: glasses - 1);

  /// Changes the daily wellness goal, clamped to the allowed range.
  HydrationRecord withGoal(int newGoal) => copyWith(goal: newGoal);

  /// Completion ratio in the 0..1 range, safe when the goal is zero.
  double get progress {
    if (goal <= 0) return 0;
    final value = glasses / goal;
    return value.clamp(0.0, 1.0);
  }

  /// True once the user reached their own configured goal.
  bool get goalReached => goal > 0 && glasses >= goal;

  static int _clampCount(dynamic value, {required int fallback}) {
    if (value is num) {
      final rounded = value.round();
      return rounded < 0 ? 0 : rounded;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed < 0 ? 0 : parsed;
    }
    return fallback;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
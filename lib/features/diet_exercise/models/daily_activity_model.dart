import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_model.dart';
import 'hydration_model.dart';

/// Reads a Firestore timestamp-like value defensively.
DateTime? readOptionalDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

/// A manually logged activity (for example "Walking — 20 minutes").
///
/// There is no pedometer integration in this app, so activity is entered by
/// the user rather than read from the device.
class ActivityEntry {
  final String id;
  final String name;
  final int minutes;
  final DateTime? loggedAt;

  const ActivityEntry({
    required this.id,
    required this.name,
    required this.minutes,
    this.loggedAt,
  });

  factory ActivityEntry.fromMap(String id, Map<String, dynamic> map) {
    final rawMinutes = map['minutes'];
    return ActivityEntry(
      id: id,
      name: map['name'] is String ? map['name'] as String : '',
      minutes: rawMinutes is num && rawMinutes > 0 ? rawMinutes.round() : 0,
      loggedAt: readOptionalDate(map['loggedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'minutes': minutes,
        if (loggedAt != null) 'loggedAt': Timestamp.fromDate(loggedAt!),
      };

  /// e.g. `Walking — 20 min`.
  String get summaryLabel =>
      name.isEmpty ? '$minutes min' : '$name — $minutes min';
}

/// Manually recorded activity for one day, stored under
/// `users/{uid}/daily_activity/{date}`.
class DailyActivity {
  final String date;
  final int steps;
  final List<ActivityEntry> entries;
  final DateTime? updatedAt;

  const DailyActivity({
    required this.date,
    this.steps = 0,
    this.entries = const [],
    this.updatedAt,
  });

  factory DailyActivity.fromMap(String date, Map<String, dynamic> map) {
    final rawEntries = map['entries'];
    final entries = <ActivityEntry>[];
    if (rawEntries is List) {
      for (final entry in rawEntries) {
        if (entry is Map) {
          entries.add(ActivityEntry.fromMap(
            entry['id'] is String ? entry['id'] as String : entries.length.toString(),
            Map<String, dynamic>.from(entry),
          ));
        }
      }
    }
    final rawSteps = map['steps'];
    return DailyActivity(
      date: date,
      steps: rawSteps is num && rawSteps > 0 ? rawSteps.round() : 0,
      entries: entries,
      updatedAt: readOptionalDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) => {
        'date': date,
        'steps': steps,
        'entries': entries.map((entry) => entry.toMap()).toList(),
        if (includeTimestamps) 'updatedAt': Timestamp.now(),
      };

  DailyActivity copyWith({
    int? steps,
    List<ActivityEntry>? entries,
    DateTime? updatedAt,
  }) {
    return DailyActivity(
      date: date,
      steps: steps == null ? this.steps : (steps < 0 ? 0 : steps),
      entries: entries ?? this.entries,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Total minutes from manually logged entries. Never negative.
  int get manualMinutes => entries.fold<int>(
      0, (total, entry) => total + (entry.minutes < 0 ? 0 : entry.minutes));

  int get entryCount => entries.length;

  bool get isEmpty => entries.isEmpty && steps == 0;

  /// Appends [entry]. Negative durations are rejected (stored as zero).
  DailyActivity addEntry(ActivityEntry entry) {
    final sanitised = entry.minutes < 0
        ? ActivityEntry(id: entry.id, name: entry.name, minutes: 0)
        : entry;
    return copyWith(entries: [...entries, sanitised]);
  }

  /// Removes the entry with [entryId] when it exists.
  DailyActivity removeEntry(String entryId) {
    if (!entries.any((entry) => entry.id == entryId)) return this;
    return copyWith(
      entries: entries.where((entry) => entry.id != entryId).toList(),
    );
  }
}

/// Combined view of one day, merging hydration, workouts and manual activity.
class DailyActivitySummary {
  final String date;
  final int waterGlasses;
  final int waterGoal;
  final int exerciseMinutes;
  final int completedExercises;
  final int steps;

  const DailyActivitySummary({
    required this.date,
    this.waterGlasses = 0,
    this.waterGoal = 8,
    this.exerciseMinutes = 0,
    this.completedExercises = 0,
    this.steps = 0,
  });

  /// Builds the aggregate from the three per-day documents.
  factory DailyActivitySummary.fromParts({
    required String date,
    required HydrationRecord hydration,
    required WorkoutRecord workout,
    required DailyActivity activity,
  }) {
    return DailyActivitySummary(
      date: date,
      waterGlasses: hydration.glasses,
      waterGoal: hydration.goal,
      exerciseMinutes: workout.minutes + activity.manualMinutes,
      completedExercises: workout.completedCount,
      steps: activity.steps,
    );
  }

  /// Fraction of the water goal reached, clamped to 0..1.
  double get waterProgress {
    if (waterGoal <= 0) return 0;
    return (waterGlasses / waterGoal).clamp(0.0, 1.0);
  }

  bool get hasAnyActivity =>
      waterGlasses > 0 || exerciseMinutes > 0 || completedExercises > 0;
}
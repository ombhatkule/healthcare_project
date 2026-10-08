import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Categories used to group the exercise library.
enum ExerciseCategory {
  walking('Walking', Icons.directions_walk_outlined),
  cardio('Cardio', Icons.directions_run_outlined),
  strength('Strength', Icons.fitness_center_outlined),
  flexibility('Flexibility', Icons.self_improvement_outlined),
  mobility('Mobility', Icons.accessibility_new_outlined),
  breathing('Breathing / Relaxation', Icons.air_outlined);

  const ExerciseCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  String get key => name;

  static ExerciseCategory? fromKey(String? key) {
    if (key == null) return null;
    for (final category in ExerciseCategory.values) {
      if (category.key == key) return category;
    }
    return null;
  }
}

/// How demanding an exercise is. Purely informational — no progression advice.
enum ExerciseDifficulty {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const ExerciseDifficulty(this.label);

  final String label;

  String get key => name;

  static ExerciseDifficulty fromKey(String? key) {
    for (final difficulty in ExerciseDifficulty.values) {
      if (difficulty.key == key) return difficulty;
    }
    return ExerciseDifficulty.beginner;
  }
}

/// A single exercise from the library.
///
/// [safetyNote] is mandatory and is always rendered with the exercise so the
/// user knows when to stop. Durations are general wellness suggestions and can
/// be shortened by the user.
class ExerciseItem {
  final String id;
  final String name;
  final ExerciseCategory category;
  final int durationMinutes;
  final ExerciseDifficulty difficulty;
  final String description;
  final String instructions;
  final String safetyNote;
  final List<String> steps;

  const ExerciseItem({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.difficulty,
    required this.description,
    required this.instructions,
    required this.safetyNote,
    this.steps = const [],
  });

  factory ExerciseItem.fromMap(Map<String, dynamic> map) {
    final rawSteps = map['steps'];
    final steps = <String>[];
    if (rawSteps is List) {
      for (final step in rawSteps) {
        if (step is String && step.trim().isNotEmpty) steps.add(step);
      }
    }
    return ExerciseItem(
      id: map['id'] is String ? map['id'] as String : '',
      name: map['name'] is String ? map['name'] as String : '',
      category: ExerciseCategory.fromKey(map['category'] as String?) ??
          ExerciseCategory.walking,
      durationMinutes: _positiveInt(map['durationMinutes'], fallback: 5),
      difficulty: ExerciseDifficulty.fromKey(map['difficulty'] as String?),
      description: map['description'] is String
          ? map['description'] as String
          : '',
      instructions: map['instructions'] is String
          ? map['instructions'] as String
          : '',
      safetyNote: map['safetyNote'] is String ? map['safetyNote'] as String : '',
      steps: steps,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category.key,
        'durationMinutes': durationMinutes,
        'difficulty': difficulty.key,
        'description': description,
        'instructions': instructions,
        'safetyNote': safetyNote,
        if (steps.isNotEmpty) 'steps': steps,
      };

  ExerciseItem copyWith({
    String? id,
    String? name,
    ExerciseCategory? category,
    int? durationMinutes,
    ExerciseDifficulty? difficulty,
    String? description,
    String? instructions,
    String? safetyNote,
    List<String>? steps,
  }) {
    return ExerciseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      safetyNote: safetyNote ?? this.safetyNote,
      steps: steps ?? this.steps,
    );
  }

  /// e.g. `15 min · Beginner`.
  String get summaryLabel => '$durationMinutes min · ${difficulty.label}';

  static int _positiveInt(dynamic value, {required int fallback}) {
    if (value is num) {
      final rounded = value.round();
      return rounded > 0 ? rounded : fallback;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return fallback;
  }
}

/// A completed-exercise record for a single day.
///
/// The set of ids guarantees an exercise can never be counted twice, even if
/// the completion action is triggered repeatedly.
class WorkoutRecord {
  final String date;
  final Set<String> completedExerciseIds;
  final int minutes;
  final DateTime? updatedAt;

  const WorkoutRecord({
    required this.date,
    this.completedExerciseIds = const {},
    this.minutes = 0,
    this.updatedAt,
  });

  factory WorkoutRecord.fromMap(String date, Map<String, dynamic> map) {
    final rawIds = map['completedExerciseIds'];
    final ids = <String>{};
    if (rawIds is List) {
      for (final id in rawIds) {
        if (id is String && id.trim().isNotEmpty) ids.add(id);
      }
    }
    final rawMinutes = map['minutes'];
    return WorkoutRecord(
      date: date,
      completedExerciseIds: ids,
      minutes: rawMinutes is num && rawMinutes > 0 ? rawMinutes.round() : 0,
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) => {
        'date': date,
        'completedExerciseIds': completedExerciseIds.toList(),
        'minutes': minutes,
        if (includeTimestamps) 'updatedAt': Timestamp.now(),
      };

  /// Whether [exerciseId] was already completed today.
  bool isCompleted(String exerciseId) => completedExerciseIds.contains(exerciseId);

  int get completedCount => completedExerciseIds.length;

  /// Marks [exerciseId] as done, adding [durationMinutes] the first time only.
  ///
  /// Re-completing the same exercise is a no-op, so the tracked minutes can
  /// never be inflated by a double tap.
  WorkoutRecord markCompleted(String exerciseId, int durationMinutes) {
    if (exerciseId.trim().isEmpty) return this;
    if (isCompleted(exerciseId)) return this;
    return WorkoutRecord(
      date: date,
      completedExerciseIds: {...completedExerciseIds, exerciseId},
      minutes: minutes + (durationMinutes < 0 ? 0 : durationMinutes),
      updatedAt: DateTime.now(),
    );
  }

  /// Removes [exerciseId].
  ///
  /// The minute total is recomputed from [catalog] so un-marking can never
  /// leave the tracked minutes out of sync with the completed set.
  WorkoutRecord markNotCompleted(
      String exerciseId, List<ExerciseItem> catalog) {
    if (!isCompleted(exerciseId)) return this;
    final ids = Set<String>.of(completedExerciseIds)..remove(exerciseId);
    var total = 0;
    for (final id in ids) {
      total += _durationFor(id, catalog: catalog);
    }
    return WorkoutRecord(
      date: date,
      completedExerciseIds: ids,
      minutes: total,
      updatedAt: DateTime.now(),
    );
  }

  int _durationFor(String exerciseId, {required List<ExerciseItem> catalog}) {
    for (final exercise in catalog) {
      if (exercise.id == exerciseId) return exercise.durationMinutes;
    }
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
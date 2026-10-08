import 'exercise_model.dart';

/// Arguments for the exercise detail screen.
class ExerciseDetailArguments {
  /// Stable id of the exercise from the library.
  final String exerciseId;

  const ExerciseDetailArguments({required this.exerciseId});

  /// Resolves the exercise from the supplied [catalog], returning null when the
  /// id is unknown so the screen can show an empty state instead of crashing.
  ExerciseItem? resolve(List<ExerciseItem> catalog) {
    for (final exercise in catalog) {
      if (exercise.id == exerciseId) return exercise;
    }
    return null;
  }
}
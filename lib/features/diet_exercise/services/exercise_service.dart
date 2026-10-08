import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/exceptions.dart';
import '../models/models.dart';
import 'firestore_operation.dart';

/// The exercise library plus the persistence of completed exercises.
///
/// Exercise content is a curated, general-wellness catalogue: short,
/// low-risk movements with a safety note on every entry. Completion state lives
/// in Firestore under `users/{userId}/workouts/{date}`.
class ExerciseService {
  final FirebaseFirestore? _injectedFirestore;

  ExerciseService({FirebaseFirestore? firestore}) : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  /// Firestore path of a user's completed-exercises document for [date].
  ///
  /// Matches the `match /users/{userId}/workouts/{date}` rule and is always
  /// scoped to the authenticated UID passed in.
  static String workoutDocPath(String userId, String date) =>
      'users/$userId/workouts/$date';

  CollectionReference<Map<String, dynamic>> _workouts(String userId) =>
      _firestore.collection('users').doc(userId).collection('workouts');

  /// The full library, grouped-friendly and stable across app launches.
  static List<ExerciseItem> get catalog => _catalog;

  /// Looks up one exercise by id.
  static ExerciseItem? byId(String id) {
    for (final exercise in _catalog) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  /// Library entries for a category; passing null returns everything.
  static List<ExerciseItem> byCategory(ExerciseCategory? category) {
    if (category == null) return List.unmodifiable(_catalog);
    return _catalog.where((e) => e.category == category).toList();
  }

  /// A gentle warm-up/cool-down routine composed from the library.
  ///
  /// The routine is scaled by the user's wellness goal and activity level but
  /// always stays within beginner-safe movements.
  static List<ExerciseItem> dailyRoutine({
    DietExercisePreferences preferences = const DietExercisePreferences(),
  }) {
    final core = switch (preferences.goal) {
      WellnessGoal.generalFitness => ['warm_up_marching', 'walk_brisk', 'stretch_neck', 'cool_down_breathing'],
      WellnessGoal.weightManagement => ['warm_up_marching', 'walk_brisk', 'stretch_full_body', 'cool_down_breathing'],
      WellnessGoal.improveActivity => ['warm_up_marching', 'walk_moderate', 'bodyweight_squat', 'stretch_full_body'],
      WellnessGoal.improveFlexibility => ['stretch_neck', 'stretch_full_body', 'mobility_ankle', 'cool_down_breathing'],
      WellnessGoal.healthyRoutine => ['warm_up_marching', 'walk_brisk', 'breathing_deep', 'cool_down_breathing'],
    };

    final routine = <ExerciseItem>[];
    for (final id in core) {
      final exercise = byId(id);
      if (exercise != null) routine.add(exercise);
    }
    return routine;
  }

  /// Loads the completed-exercise record for [date].
  ///
  /// A missing document resolves to an empty record instead of an error, so a
  /// fresh user always sees a usable screen.
  Future<WorkoutRecord> loadWorkout(String userId, String date) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot = await runFirestoreOperation(
        operation: () => _firestore.doc(workoutDocPath(userId, date)).get(),
        failureMessage:
            'Unable to load your workout history. Please try again.',
      );
      if (!snapshot.exists) return WorkoutRecord(date: date);
      return WorkoutRecord.fromMap(date, snapshot.data() ?? const {});
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Unable to load your workout history. Please try again.',
      );
    }
  }

  /// Persists the completed-exercise record for [date].
  Future<void> saveWorkout(String userId, WorkoutRecord record) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      await runFirestoreOperation<void>(
        operation: () => _firestore.doc(workoutDocPath(userId, record.date)).set(
              record.toMap(includeTimestamps: true),
              SetOptions(merge: true),
            ),
        failureMessage: 'Unable to save your workout. Please try again.',
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Unable to save your workout. Please try again.',
      );
    }
  }

  /// Loads the completed-exercise records for a bounded set of [dates].
  ///
  /// Only the requested days are fetched, so opening the progress screen never
  /// loads the user's whole history.
  Future<Map<String, WorkoutRecord>> loadWorkoutsForDates(
    String userId,
    List<String> dates,
  ) async {
    if (dates.isEmpty) return {};
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot = await runFirestoreOperation(
        operation: () => _workouts(userId)
            .where(FieldPath.documentId, whereIn: dates)
            .get(),
        failureMessage:
            'Unable to load your recent workouts. Please try again.',
      );
      return {
        for (final doc in snapshot.docs)
          doc.id: WorkoutRecord.fromMap(doc.id, doc.data()),
      };
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Unable to load your recent workouts. Please try again.',
      );
    }
  }
}

/// Curated library. Durations are gentle general-wellness suggestions and the
/// user is always told to stop if anything feels wrong.
const List<ExerciseItem> _catalog = [
  ExerciseItem(
    id: 'walk_brisk',
    name: 'Brisk Walking',
    category: ExerciseCategory.walking,
    durationMinutes: 15,
    difficulty: ExerciseDifficulty.beginner,
    description: 'Comfortable, slightly quicker-than-usual walking.',
    instructions:
        'Walk at a comfortable pace where you could still hold a short conversation. '
        'Keep your posture upright, shoulders relaxed and arms swinging naturally.',
    safetyNote:
        'Stop if you experience pain, dizziness, unusual shortness of breath, '
        'or any other concerning symptoms. Shorten the walk if you are unsure.',
    steps: [
      'Prepare: choose flat ground and supportive footwear.',
      'Perform: start slowly for two minutes, then settle into a steady pace.',
      'Rest: pause and breathe whenever you need to.',
      'Cool down: slow down for the final two minutes.',
    ],
  ),
  ExerciseItem(
    id: 'walk_moderate',
    name: 'Moderate Pace Walking',
    category: ExerciseCategory.walking,
    durationMinutes: 20,
    difficulty: ExerciseDifficulty.beginner,
    description: 'A longer walk for building a daily movement habit.',
    instructions:
        'Walk continuously for the full duration at a pace that feels like light '
        'to moderate effort. Swing your arms and breathe evenly.',
    safetyNote:
        'Stop if you experience pain, dizziness, unusual shortness of breath, '
        'or any other concerning symptoms.',
    steps: [
      'Prepare: check the weather and wear comfortable shoes.',
      'Perform: walk at an even pace for the main part of the session.',
      'Rest: take short standing breaks if you need them.',
      'Cool down: finish with slow steps and relaxed breathing.',
    ],
  ),
  ExerciseItem(
    id: 'warm_up_marching',
    name: 'Marching in Place',
    category: ExerciseCategory.cardio,
    durationMinutes: 5,
    difficulty: ExerciseDifficulty.beginner,
    description: 'Gentle warm-up that raises your heart rate slowly.',
    instructions:
        'March on the spot lifting your knees to a comfortable height. '
        'Keep your upper body relaxed and breathe steadily.',
    safetyNote:
        'Move more slowly if you feel unsteady. Stop if you feel pain, dizziness '
        'or unusual shortness of breath.',
    steps: [
      'Prepare: stand tall with your feet hip-width apart.',
      'Perform: march steadily for the whole duration.',
      'Rest: lower your knees and stand still for a few breaths.',
      'Cool down: shake out your arms and legs.',
    ],
  ),
  ExerciseItem(
    id: 'cardio_step_touch',
    name: 'Step and Touch',
    category: ExerciseCategory.cardio,
    durationMinutes: 10,
    difficulty: ExerciseDifficulty.beginner,
    description: 'Low-impact cardio using alternating side steps.',
    instructions:
        'Step one foot to the side, bring the other foot across to touch it, then '
        'repeat on the opposite side. Keep the movement smooth and controlled.',
    safetyNote:
        'Keep the range small if balance is difficult. Stop if you feel pain or '
        'dizziness.',
    steps: [
      'Prepare: clear a small space and stand with feet together.',
      'Perform: alternate side steps with light toe touches.',
      'Rest: stand still and breathe for a few counts.',
      'Cool down: march gently in place to lower your heart rate.',
    ],
  ),
  ExerciseItem(
    id: 'bodyweight_squat',
    name: 'Bodyweight Squat',
    category: ExerciseCategory.strength,
    durationMinutes: 8,
    difficulty: ExerciseDifficulty.beginner,
    description: 'Simple lower-body strengthening using body weight only.',
    instructions:
        'Stand with feet about shoulder-width apart. Lower your hips as if sitting '
        'into a chair, keeping your back straight, then return to standing.',
    safetyNote:
        'Keep the movement shallow if you have knee, hip or back discomfort, and '
        'stop if anything hurts. Ask a qualified professional before exercising '
        'through pain.',
    steps: [
      'Prepare: stand tall with feet shoulder-width apart and arms relaxed.',
      'Perform: lower your hips slowly, then press back up to standing.',
      'Rest: pause between repetitions and breathe normally.',
      'Cool down: straighten your legs and shake them out.',
    ],
  ),
  ExerciseItem(
    id: 'strength_wall_push',
    name: 'Wall Push-ups',
    category: ExerciseCategory.strength,
    durationMinutes: 6,
    difficulty: ExerciseDifficulty.beginner,
    description: 'Upper-body strengthening against a wall for stability.',
    instructions:
        'Place your hands on a wall at chest height and walk your feet back. '
        'Bend your elbows to bring your chest closer, then press away.',
    safetyNote:
        'Use a lower position or a smaller range if you feel strain in your '
        'shoulders. Stop if anything hurts.',
    steps: [
      'Prepare: find a clear wall and stand a step away from it.',
      'Perform: bend and straighten your elbows in a controlled way.',
      'Rest: lower your arms and breathe between sets.',
      'Cool down: gently roll your shoulders back and forth.',
    ],
  ),
  ExerciseItem(
    id: 'stretch_full_body',
    name: 'Full Body Stretch',
    category: ExerciseCategory.flexibility,
    durationMinutes: 10,
    difficulty: ExerciseDifficulty.beginner,
    description: 'Gentle stretches for the back, legs and shoulders.',
    instructions:
        'Move slowly through a few simple stretches such as reaching for your '
        'toes, side bends and shoulder rolls. Hold each stretch comfortably '
        'without bouncing.',
    safetyNote:
        'Never stretch into sharp pain. Stop if you feel pain, tingling or '
        'dizziness and consult a qualified professional if symptoms persist.',
    steps: [
      'Prepare: stand or sit comfortably and take a few deep breaths.',
      'Perform: hold each stretch for a comfortable amount of time.',
      'Rest: release each stretch slowly and pause before the next one.',
      'Cool down: lie or sit comfortably for a moment of slow breathing.',
    ],
  ),
  ExerciseItem(
    id: 'stretch_neck',
    name: 'Neck and Shoulder Stretches',
    category: ExerciseCategory.flexibility,
    durationMinutes: 5,
    difficulty: ExerciseDifficulty.beginner,
    description: 'Slow, controlled movements to reduce neck stiffness.',
    instructions:
        'Tilt your head gently to one side, hold, then switch sides. Follow with '
        'slow shoulder rolls. Keep your shoulders relaxed.',
    safetyNote:
        'Move slowly and never force the movement. Stop if you feel pain, '
        'tingling or dizziness.',
    steps: [
      'Prepare: sit or stand tall with shoulders relaxed.',
      'Perform: tilt each side gently and roll your shoulders slowly.',
      'Rest: return to neutral between movements.',
      'Cool down: relax your arms and breathe slowly.',
    ],
  ),
  ExerciseItem(
    id: 'mobility_ankle',
    name: 'Ankle Mobility Circles',
    category: ExerciseCategory.mobility,
    durationMinutes: 5,
    difficulty: ExerciseDifficulty.beginner,
    description: 'Gentle ankle movement to maintain comfortable mobility.',
    instructions:
        'Lift one foot slightly and draw slow circles with your toes, then change '
        'direction and repeat. Switch feet afterwards.',
    safetyNote:
        'Keep the circles small if your ankle feels stiff. Stop if you feel pain '
        'or instability.',
    steps: [
      'Prepare: stand holding a wall or chair for balance.',
      'Perform: draw slow circles with each foot in turn.',
      'Rest: lower your foot and shake it out gently.',
      'Cool down: stand still and relax both ankles.',
    ],
  ),
  ExerciseItem(
    id: 'mobility_hip',
    name: 'Seated Hip Flexor Mobility',
    category: ExerciseCategory.mobility,
    durationMinutes: 6,
    difficulty: ExerciseDifficulty.beginner,
    description: 'A seated stretch for hips and lower back.',
    instructions:
        'Sit tall on a chair, place one foot slightly forward and gently lean '
        'your torso back until you feel a mild stretch, then swap legs.',
    safetyNote:
        'Stay within a comfortable range. Stop if you feel pain or numbness and '
        'seek advice from a qualified professional if it persists.',
    steps: [
      'Prepare: sit on a stable chair with both feet on the floor.',
      'Perform: lean back gently into a mild stretch, then change legs.',
      'Rest: return to an upright posture and breathe.',
      'Cool down: relax your shoulders and breathe slowly.',
    ],
  ),
  ExerciseItem(
    id: 'breathing_deep',
    name: 'Deep Breathing',
    category: ExerciseCategory.breathing,
    durationMinutes: 5,
    difficulty: ExerciseDifficulty.beginner,
    description: 'Slow breathing exercise to help you relax.',
    instructions:
        'Sit comfortably, breathe in slowly through your nose for a count of '
        'four, hold gently, and exhale slowly through your mouth for a count of '
        'six. Repeat at a comfortable pace.',
    safetyNote:
        'Breathe normally if holding your breath feels uncomfortable. Stop if you '
        'feel light-headed.',
    steps: [
      'Prepare: sit or lie down somewhere comfortable.',
      'Perform: breathe in slowly, hold gently, then breathe out slowly.',
      'Rest: return to normal breathing between rounds.',
      'Cool down: finish with three slow, natural breaths.',
    ],
  ),
  ExerciseItem(
    id: 'cool_down_breathing',
    name: 'Cool-down Breathing',
    category: ExerciseCategory.breathing,
    durationMinutes: 5,
    difficulty: ExerciseDifficulty.beginner,
    description: 'Gentle breathing to bring your breathing back to normal.',
    instructions:
        'Stand or sit relaxed and take slow, even breaths, letting your shoulders '
        'drop with each exhale.',
    safetyNote:
        'Keep the breathing gentle and return to normal breathing if anything '
        'feels uncomfortable.',
    steps: [
      'Prepare: stop moving and find a comfortable position.',
      'Perform: breathe slowly and evenly for the duration.',
      'Rest: breathe normally between deeper breaths.',
      'Cool down: finish with a few relaxed, natural breaths.',
    ],
  ),
];
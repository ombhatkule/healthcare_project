import 'dart:async';

import 'package:healthcare_app/core/errors/exceptions.dart';
import 'package:healthcare_app/features/diet_exercise/models/models.dart';
import 'package:healthcare_app/features/diet_exercise/services/services.dart';
import 'package:healthcare_app/features/profile/models/user_profile.dart';

/// In-memory doubles for the Phase 15 services.
///
/// They keep everything in plain maps so controller tests never touch the
/// Firebase SDK, and they can be told to fail in order to exercise the error
/// and rollback paths.

/// Error thrown by the fakes, shaped like a real [AppException].
const String _failureMessage = 'Firestore unavailable. Please try again.';

/// A [DietService] backed by an in-memory preferences document.
class FakeDietService extends DietService {
  FakeDietService({
    DietExercisePreferences? preferences,
    this.shouldThrow = false,
    this.failure,
    this.hang = false,
  }) : stored = preferences ?? const DietExercisePreferences();

  /// Current "Firestore" preferences document.
  DietExercisePreferences stored;

  /// When true every call throws, simulating a Firestore failure.
  bool shouldThrow;

  /// When set, this object is thrown instead of reading the document, so a
  /// test can simulate permission denied, a network error or a timeout with
  /// the exact shape a real Firestore call would produce.
  Object? failure;

  /// When true the read never completes, so the caller has to give up on its
  /// own (this is how a hung Firestore connection is modelled).
  bool hang;

  /// Number of times [savePreferences] was called.
  int saveCount = 0;

  /// The uid of the most recent call, so tests can verify the authenticated
  /// Firebase UID is the one used to build the user-scoped Firestore path.
  String? lastUserId;

  @override
  Future<DietExercisePreferences> loadPreferences(String userId) async {
    lastUserId = userId;
    if (hang) {
      return Completer<DietExercisePreferences>().future;
    }
    if (failure != null) throw failure!;
    if (shouldThrow) throw const AppException(message: _failureMessage);
    return stored;
  }

  @override
  Future<void> savePreferences(
    String userId,
    DietExercisePreferences preferences,
  ) async {
    lastUserId = userId;
    if (failure != null) throw failure!;
    if (shouldThrow) throw const AppException(message: _failureMessage);
    saveCount++;
    stored = preferences;
  }

  @override
  DietPlan buildDietPlan({
    DietExercisePreferences? preferences,
    UserProfile? profile,
  }) {
    return super.buildDietPlan(
      preferences: preferences ?? stored,
      profile: profile,
    );
  }
}

/// An [ExerciseService] that keeps one [WorkoutRecord] per day in memory.
class FakeExerciseService extends ExerciseService {
  FakeExerciseService({
    Map<String, WorkoutRecord>? workouts,
    this.shouldThrow = false,
  }) : workouts = workouts ?? <String, WorkoutRecord>{};

  final Map<String, WorkoutRecord> workouts;
  bool shouldThrow;

  /// The uid of the most recent call (ownership check for tests).
  String? lastUserId;

  @override
  Future<WorkoutRecord> loadWorkout(String userId, String date) async {
    lastUserId = userId;
    if (shouldThrow) throw const AppException(message: _failureMessage);
    return workouts[date] ?? WorkoutRecord(date: date);
  }

  @override
  Future<void> saveWorkout(String userId, WorkoutRecord record) async {
    lastUserId = userId;
    if (shouldThrow) throw const AppException(message: _failureMessage);
    workouts[record.date] = record;
  }

  @override
  Future<Map<String, WorkoutRecord>> loadWorkoutsForDates(
    String userId,
    List<String> dates,
  ) async {
    if (shouldThrow) throw const AppException(message: _failureMessage);
    final result = <String, WorkoutRecord>{};
    for (final date in dates) {
      final record = workouts[date];
      if (record != null) result[date] = record;
    }
    return result;
  }
}

/// An [ActivityTrackingService] keeping hydration and activity per day.
class FakeActivityTrackingService extends ActivityTrackingService {
  FakeActivityTrackingService({
    Map<String, HydrationRecord>? hydration,
    Map<String, DailyActivity>? activity,
    this.shouldThrow = false,
  })  : hydration = hydration ?? <String, HydrationRecord>{},
        activity = activity ?? <String, DailyActivity>{};

  final Map<String, HydrationRecord> hydration;
  final Map<String, DailyActivity> activity;
  bool shouldThrow;

  /// The uid of the most recent call (ownership check for tests).
  String? lastUserId;

  @override
  Future<HydrationRecord> loadHydration(String userId, String date) async {
    lastUserId = userId;
    if (shouldThrow) throw const AppException(message: _failureMessage);
    return hydration[date] ?? HydrationRecord(date: date);
  }

  @override
  Future<void> saveHydration(String userId, HydrationRecord record) async {
    lastUserId = userId;
    if (shouldThrow) throw const AppException(message: _failureMessage);
    hydration[record.date] = record;
  }

  @override
  Future<DailyActivity> loadActivity(String userId, String date) async {
    lastUserId = userId;
    if (shouldThrow) throw const AppException(message: _failureMessage);
    return activity[date] ?? DailyActivity(date: date);
  }

  @override
  Future<void> saveActivity(String userId, DailyActivity value) async {
    lastUserId = userId;
    if (shouldThrow) throw const AppException(message: _failureMessage);
    activity[value.date] = value;
  }

  @override
  Future<Map<String, HydrationRecord>> loadHydrationForDates(
    String userId,
    List<String> dates,
  ) async {
    if (shouldThrow) throw const AppException(message: _failureMessage);
    final result = <String, HydrationRecord>{};
    for (final date in dates) {
      final record = hydration[date];
      if (record != null) result[date] = record;
    }
    return result;
  }

  @override
  Future<Map<String, DailyActivity>> loadActivityForDates(
    String userId,
    List<String> dates,
  ) async {
    if (shouldThrow) throw const AppException(message: _failureMessage);
    final result = <String, DailyActivity>{};
    for (final date in dates) {
      final record = activity[date];
      if (record != null) result[date] = record;
    }
    return result;
  }
}
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../profile/models/user_profile.dart';
import '../../models/models.dart';
import '../../services/services.dart';

/// State management for the Phase 15 Diet & Exercise module.
///
/// Reads and writes happen through the injected services; this controller only
/// owns UI-facing state and the aggregation of the three per-day documents
/// (water, workouts and manual activity) into a single daily summary.
///
/// All updates are applied optimistically and rolled back when persistence
/// fails, so the screen stays usable while offline and the user always sees a
/// consistent value.
class DietExerciseController extends ChangeNotifier {
  /// Controller-level guard for a single load/history read.
  ///
  /// Each Firestore call already times out after
  /// [firestoreOperationTimeout] (15s); this is a second, slightly looser
  /// bound so `await`s inside `load`/`loadHistory` can never hang forever and
  /// leave `isLoading` stuck at true.
  ///
  /// Not `const` only so tests can shrink it and exercise the hanging-read
  /// path without waiting the production 20 seconds.
  static Duration loadTimeout = const Duration(seconds: 20);

  final DietService _dietService;
  final ExerciseService _exerciseService;
  final ActivityTrackingService _activityService;

  DietExerciseController({
    DietService? dietService,
    ExerciseService? exerciseService,
    ActivityTrackingService? activityService,
  })  : _dietService = dietService ?? DietService(),
        _exerciseService = exerciseService ?? ExerciseService(),
        _activityService = activityService ?? ActivityTrackingService();

  DietExercisePreferences _preferences = const DietExercisePreferences();
  HydrationRecord _hydration = HydrationRecord(date: '');
  WorkoutRecord _workout = WorkoutRecord(date: '');
  DailyActivity _activity = DailyActivity(date: '');
  List<DailyActivitySummary> _history = const [];
  UserProfile? _profile;
  String _date = '';

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isHistoryLoading = false;
  String? _errorMessage;
  String? _userId;

  // ---------------------------------------------------------------------
  // Read-only state
  // ---------------------------------------------------------------------

  DietExercisePreferences get preferences => _preferences;
  HydrationRecord get hydration => _hydration;
  WorkoutRecord get workout => _workout;
  DailyActivity get activity => _activity;
  List<DailyActivitySummary> get history => List.unmodifiable(_history);
  UserProfile? get profile => _profile;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isSignedIn => _userId != null && _userId!.isNotEmpty;

  /// The day key currently held in memory.
  String get date => _date;

  /// Curated exercise library.
  List<ExerciseItem> get exerciseCatalog => ExerciseService.catalog;

  /// Today's suggested routine, scaled to the stored wellness goal.
  List<ExerciseItem> get dailyRoutine =>
      ExerciseService.dailyRoutine(preferences: _preferences);

  /// Whether the user already marked [exerciseId] as done today.
  bool isExerciseCompleted(String exerciseId) =>
      _workout.isCompleted(exerciseId);

  int get waterGlasses => _hydration.glasses;
  int get waterGoal => _hydration.goal;
  double get waterProgress => _hydration.progress;
  bool get waterGoalReached => _hydration.goalReached;

  /// Minutes from completed exercises plus manually logged activity.
  int get exerciseMinutes => _workout.minutes + _activity.manualMinutes;
  int get completedExerciseCount => _workout.completedCount;
  int get manualActivityMinutes => _activity.manualMinutes;
  int get steps => _activity.steps;
  List<ActivityEntry> get activityEntries => List.unmodifiable(_activity.entries);

  int get exerciseGoalMinutes => _preferences.dailyExerciseGoalMinutes;

  /// Fraction of the user's own exercise goal reached (0..1).
  double get exerciseProgress {
    if (exerciseGoalMinutes <= 0) return 0;
    return (exerciseMinutes / exerciseGoalMinutes).clamp(0.0, 1.0);
  }

  /// Aggregated view of today across hydration, workouts and manual activity.
  DailyActivitySummary get todaySummary => DailyActivitySummary.fromParts(
        date: _date,
        hydration: _hydration,
        workout: _workout,
        activity: _activity,
      );

  /// The diet plan for today, rebuilt whenever preferences or the profile change.
  DietPlan get dietPlan =>
      _dietService.buildDietPlan(preferences: _preferences, profile: _profile);

  // ---------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------

  /// Keeps the controller's personalization inputs in sync with the profile.
  void setProfile(UserProfile? profile) {
    if (identical(profile, _profile)) return;
    _profile = profile;
    notifyListeners();
  }

  /// Loads preferences plus today's tracking state for [userId].
  ///
  /// The four reads are started together and are fully independent: a failure
  /// in one of them (missing document, permission error, timeout) falls back
  /// to a safe default for that slice and is reported as a banner message.
  /// The static meal plan and exercise library never depend on Firestore, so
  /// a Firestore problem can no longer blank the whole module.
  ///
  /// Every Future completes (each read carries its own timeout) and the
  /// loading flag is always reset in `finally`.
  Future<void> load(String userId) async {
    _userId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final today = dateKeyOf(DateTime.now());
      _date = today;

      final preferencesFuture = _attempt<DietExercisePreferences>(
        () => _dietService.loadPreferences(userId),
        fallback: const DietExercisePreferences(),
        failureMessage: AppStrings.preferencesLoadFailed,
      );
      final hydrationFuture = _attempt<HydrationRecord>(
        () => _activityService.loadHydration(userId, today),
        fallback: HydrationRecord(date: today),
        failureMessage:
            'Unable to load your water intake right now. Please try again.',
      );
      final workoutFuture = _attempt<WorkoutRecord>(
        () => _exerciseService.loadWorkout(userId, today),
        fallback: WorkoutRecord(date: today),
        failureMessage:
            'Unable to load your workout history. Please try again.',
      );
      final activityFuture = _attempt<DailyActivity>(
        () => _activityService.loadActivity(userId, today),
        fallback: DailyActivity(date: today),
        failureMessage:
            'Unable to load your activity right now. Please try again.',
      );

      final preferences = await preferencesFuture;
      final hydration = await hydrationFuture;
      final workout = await workoutFuture;
      final activity = await activityFuture;

      _preferences = preferences.value;
      _hydration = hydration.value;
      _workout = workout.value;
      _activity = activity.value;

      // The stored water goal is the user's own preference, so today's counter
      // always starts from it (a new day has no hydration document yet).
      if (_hydration.goal != _preferences.waterGoal) {
        _hydration = _hydration.copyWith(goal: _preferences.waterGoal);
      }

      _errorMessage = _mergeErrors([
        preferences.error,
        hydration.error,
        workout.error,
        activity.error,
      ]);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = AppStrings.dietExerciseLoadFailed;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Awaits [run] under [loadTimeout] without ever throwing.
  ///
  /// Returns either the loaded value or [fallback] plus a safe, classified
  /// failure message, so one broken read can never cancel its siblings or
  /// escape into the UI as an unhandled error.
  Future<({T value, String? error})> _attempt<T>(
    Future<T> Function() run, {
    required T fallback,
    required String failureMessage,
  }) async {
    try {
      return (value: await run().timeout(loadTimeout), error: null);
    } on TimeoutException {
      return (value: fallback, error: firestoreTimeoutMessage);
    } on AppException catch (e) {
      return (value: fallback, error: e.message);
    } catch (e) {
      return (value: fallback, error: mapFirestoreError(e, failureMessage));
    }
  }

  /// Collapses the per-slice failures into one banner message, dropping
  /// duplicates so four identical permission errors show up once.
  static String? _mergeErrors(List<String?> errors) {
    final distinct = <String>{};
    for (final error in errors) {
      if (error != null && error.isNotEmpty) distinct.add(error);
    }
    if (distinct.isEmpty) return null;
    return distinct.join('\n');
  }

  /// Reloads today's data for the currently loaded user.
  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    await load(userId);
  }

  /// Adds one glass of water. Never goes below zero.
  Future<bool> incrementWater(String userId) =>
      _updateWater(userId, (current) => current.increment());

  /// Removes one glass of water. Stops at zero instead of going negative.
  Future<bool> decrementWater(String userId) =>
      _updateWater(userId, (current) => current.decrement());

  Future<bool> _updateWater(
    String userId,
    HydrationRecord Function(HydrationRecord current) transform,
  ) async {
    final previous = _hydration;
    final updated = transform(previous);
    if (updated.glasses == previous.glasses && updated.goal == previous.goal) {
      // Nothing to do (e.g. decrementing at zero) — stay silent and avoid a
      // pointless write.
      return false;
    }

    _hydration = updated;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _activityService.saveHydration(userId, updated);
      return true;
    } on AppException catch (e) {
      _hydration = previous;
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _hydration = previous;
      _errorMessage = AppStrings.waterSaveFailed;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Updates the user's own water goal (clamped by [HydrationRecord]).
  Future<bool> setWaterGoal(String userId, int goal) async {
    final previous = _hydration;
    final previousPreferences = _preferences;
    final updated = previous.withGoal(goal);
    if (updated.goal == previous.goal) return false;

    _hydration = updated;
    _preferences = _preferences.copyWith(waterGoal: updated.goal);
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _activityService.saveHydration(userId, updated);
      await _dietService.savePreferences(userId, _preferences);
      return true;
    } on AppException catch (e) {
      _hydration = previous;
      _preferences = previousPreferences;
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _hydration = previous;
      _preferences = previousPreferences;
      _errorMessage = AppStrings.waterSaveFailed;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Marks an exercise as completed, or un-marks it when already completed.
  ///
  /// Completion is never triggered by opening the detail screen — only by this
  /// explicit action. Re-completing is a no-op, so minutes can never be counted
  /// twice.
  Future<bool> toggleExercise(String userId, ExerciseItem exercise) async {
    final previous = _workout;
    final alreadyCompleted = previous.isCompleted(exercise.id);
    final updated = alreadyCompleted
        ? previous.markNotCompleted(exercise.id, ExerciseService.catalog)
        : previous.markCompleted(exercise.id, exercise.durationMinutes);

    _workout = updated;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _exerciseService.saveWorkout(userId, updated);
      return true;
    } on AppException catch (e) {
      _workout = previous;
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _workout = previous;
      _errorMessage = AppStrings.workoutSaveFailed;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

/// Logs a manual activity entry.
  ///
  /// [steps] can carry the manually typed step count in the same operation, so
  /// both values are written to the day document in a single save.
  ///
  /// Returns false (with a message) when the name is empty or the duration is
  /// not a positive number.
  Future<bool> addActivityEntry(
    String userId, {
    required String name,
    required int minutes,
    int? steps,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = AppStrings.activityNameRequired;
      notifyListeners();
      return false;
    }
    if (minutes <= 0) {
      _errorMessage = AppStrings.activityDurationInvalid;
      notifyListeners();
      return false;
    }
    if (steps != null && steps < 0) {
      _errorMessage = AppStrings.stepsInvalid;
      notifyListeners();
      return false;
    }

    final previous = _activity;
    final entry = ActivityEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: trimmedName,
      minutes: minutes,
      loggedAt: DateTime.now(),
    );
    _activity = steps == null
        ? previous.addEntry(entry)
        : previous.addEntry(entry).copyWith(steps: steps);
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _activityService.saveActivity(userId, _activity);
      return true;
    } on AppException catch (e) {
      _activity = previous;
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _activity = previous;
      _errorMessage = AppStrings.activitySaveFailed;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Removes a previously logged manual activity entry.
  Future<bool> removeActivityEntry(String userId, String entryId) async {
    final previous = _activity;
    final updated = previous.removeEntry(entryId);
    if (identical(updated, previous)) return false;

    _activity = updated;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _activityService.saveActivity(userId, updated);
      return true;
    } on AppException catch (e) {
      _activity = previous;
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _activity = previous;
      _errorMessage = AppStrings.activitySaveFailed;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Stores a manually entered step count for today.
  ///
  /// The app has no pedometer integration, so this value always comes from the
  /// user typing it in. Negative input is rejected.
  Future<bool> logSteps(String userId, int steps) async {
    if (steps < 0) {
      _errorMessage = AppStrings.stepsInvalid;
      notifyListeners();
      return false;
    }
    final previous = _activity;
    final updated = previous.copyWith(steps: steps);
    if (updated.steps == previous.steps) return false;

    _activity = updated;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _activityService.saveActivity(userId, updated);
      return true;
    } on AppException catch (e) {
      _activity = previous;
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _activity = previous;
      _errorMessage = AppStrings.activitySaveFailed;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Persists the wellness preferences (goal, food preference, activity level).
  Future<bool> savePreferences(
      String userId, DietExercisePreferences preferences) async {
    final previous = _preferences;
    final previousHydration = _hydration;
    _preferences = preferences.copyWith(hasSelectedGoal: true);
    // A new water goal applies to today straight away (and is kept on the
    // counter itself so both documents stay in agreement).
    _hydration = _hydration.copyWith(goal: _preferences.waterGoal);
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _dietService.savePreferences(userId, _preferences);
      if (_hydration.goal != previousHydration.goal) {
        await _activityService.saveHydration(userId, _hydration);
      }
      return true;
    } on AppException catch (e) {
      _preferences = previous;
      _hydration = previousHydration;
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _preferences = previous;
      _hydration = previousHydration;
      _errorMessage = AppStrings.preferencesSaveFailed;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Loads the last [days] days of summaries for the progress screen.
  ///
  /// Queries are bounded to those days, so the full history is never loaded.
  /// The three reads are independent and each carries its own timeout: a
  /// failure produces a message while the missing days fall back to empty
  /// summaries instead of leaving the screen blank.
  Future<void> loadHistory(String userId, {int days = 7}) async {
    _isHistoryLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final today = DateTime.now();
      final dates = <String>[];
      for (var offset = days - 1; offset >= 0; offset--) {
        dates.add(dateKeyOf(today.subtract(Duration(days: offset))));
      }

      final hydrationFuture = _attempt<Map<String, HydrationRecord>>(
        () => _activityService.loadHydrationForDates(userId, dates),
        fallback: const {},
        failureMessage:
            'Unable to load your recent water intake. Please try again.',
      );
      final workoutsFuture = _attempt<Map<String, WorkoutRecord>>(
        () => _exerciseService.loadWorkoutsForDates(userId, dates),
        fallback: const {},
        failureMessage:
            'Unable to load your recent workouts. Please try again.',
      );
      final activityFuture = _attempt<Map<String, DailyActivity>>(
        () => _activityService.loadActivityForDates(userId, dates),
        fallback: const {},
        failureMessage:
            'Unable to load your recent activity. Please try again.',
      );

      final hydration = await hydrationFuture;
      final workouts = await workoutsFuture;
      final activity = await activityFuture;

      _history = dates
          .map(
            (date) => DailyActivitySummary.fromParts(
              date: date,
              hydration: hydration.value[date] ?? HydrationRecord(date: date),
              workout: workouts.value[date] ?? WorkoutRecord(date: date),
              activity: activity.value[date] ?? DailyActivity(date: date),
            ),
          )
          .toList();

      _errorMessage = _mergeErrors([
        hydration.error,
        workouts.error,
        activity.error,
      ]);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = AppStrings.historyLoadFailed;
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears all in-memory state, used when the user signs out so no previous
  /// user's data can leak into the next session.
  void reset() {
    _preferences = const DietExercisePreferences();
    _hydration = HydrationRecord(date: '');
    _workout = WorkoutRecord(date: '');
    _activity = DailyActivity(date: '');
    _history = const [];
    _profile = null;
    _date = '';
    _userId = null;
    _errorMessage = null;
    _isLoading = false;
    _isSaving = false;
    _isHistoryLoading = false;
    notifyListeners();
  }
}

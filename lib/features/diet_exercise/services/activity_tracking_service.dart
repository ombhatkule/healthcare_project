import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/exceptions.dart';
import '../models/models.dart';
import 'firestore_operation.dart';

/// Reads and writes the per-day wellness tracking documents.
///
/// Storage layout (each document is keyed by the `yyyy-MM-dd` day key and uses
/// the app's existing `users/{uid}/<collection>/{docId}` convention):
///  - `users/{uid}/water_intake/{date}`
///  - `users/{uid}/daily_activity/{date}`
///
/// Only the requested days are ever fetched; history reads are bounded by an
/// explicit day range instead of loading the whole collection.
class ActivityTrackingService {
  final FirebaseFirestore? _injectedFirestore;

  ActivityTrackingService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  static const String waterCollection = 'water_intake';
  static const String activityCollection = 'daily_activity';

  /// Firestore path of a user's water document for [date].
  ///
  /// Matches `match /users/{userId}/water_intake/{date}` and is scoped to the
  /// authenticated UID passed in.
  static String waterDocPath(String userId, String date) =>
      'users/$userId/$waterCollection/$date';

  /// Firestore path of a user's daily-activity document for [date].
  ///
  /// Matches `match /users/{userId}/daily_activity/{date}` and is scoped to the
  /// authenticated UID passed in.
  static String activityDocPath(String userId, String date) =>
      'users/$userId/$activityCollection/$date';

  CollectionReference<Map<String, dynamic>> _sub(String userId, String name) =>
      _firestore.collection('users').doc(userId).collection(name);

  /// Loads the water record for [date], defaulting to zeros when missing.
  Future<HydrationRecord> loadHydration(String userId, String date) async {
    try {
      _requireAuth(userId);
      final snapshot = await runFirestoreOperation(
        operation: () => _firestore.doc(waterDocPath(userId, date)).get(),
        failureMessage:
            'Unable to load your water intake right now. Please try again.',
      );
      if (!snapshot.exists) return HydrationRecord(date: date);
      return HydrationRecord.fromMap(date, snapshot.data() ?? const {});
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Unable to load your water intake right now. Please try again.',
      );
    }
  }

  /// Persists the water record for [date].
  Future<void> saveHydration(String userId, HydrationRecord record) async {
    try {
      _requireAuth(userId);
      await runFirestoreOperation<void>(
        operation: () => _firestore
            .doc(waterDocPath(userId, record.date))
            .set(record.toMap(includeTimestamps: true),
                SetOptions(merge: true)),
        failureMessage:
            'Unable to save your water intake right now. Please try again.',
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Unable to save your water intake right now. Please try again.',
      );
    }
  }

  /// Loads the manually logged activity for [date].
  Future<DailyActivity> loadActivity(String userId, String date) async {
    try {
      _requireAuth(userId);
      final snapshot = await runFirestoreOperation(
        operation: () => _firestore.doc(activityDocPath(userId, date)).get(),
        failureMessage:
            'Unable to load your activity right now. Please try again.',
      );
      if (!snapshot.exists) return DailyActivity(date: date);
      return DailyActivity.fromMap(date, snapshot.data() ?? const {});
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Unable to load your activity right now. Please try again.',
      );
    }
  }

  /// Persists the manually logged activity for [date].
  Future<void> saveActivity(String userId, DailyActivity activity) async {
    try {
      _requireAuth(userId);
      await runFirestoreOperation<void>(
        operation: () => _firestore
            .doc(activityDocPath(userId, activity.date))
            .set(activity.toMap(includeTimestamps: true),
                SetOptions(merge: true)),
        failureMessage:
            'Unable to save your activity right now. Please try again.',
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Unable to save your activity right now. Please try again.',
      );
    }
  }

  /// Loads water records for a bounded set of [dates].
  Future<Map<String, HydrationRecord>> loadHydrationForDates(
    String userId,
    List<String> dates,
  ) async {
    if (dates.isEmpty) return {};
    try {
      _requireAuth(userId);
      final snapshot = await runFirestoreOperation(
        operation: () => _sub(userId, waterCollection)
            .where(FieldPath.documentId, whereIn: dates)
            .get(),
        failureMessage:
            'Unable to load your recent water intake. Please try again.',
      );
      return {
        for (final doc in snapshot.docs)
          doc.id: HydrationRecord.fromMap(doc.id, doc.data()),
      };
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Unable to load your recent water intake. Please try again.',
      );
    }
  }

  /// Loads manually logged activity for a bounded set of [dates].
  Future<Map<String, DailyActivity>> loadActivityForDates(
    String userId,
    List<String> dates,
  ) async {
    if (dates.isEmpty) return {};
    try {
      _requireAuth(userId);
      final snapshot = await runFirestoreOperation(
        operation: () => _sub(userId, activityCollection)
            .where(FieldPath.documentId, whereIn: dates)
            .get(),
        failureMessage:
            'Unable to load your recent activity. Please try again.',
      );
      return {
        for (final doc in snapshot.docs)
          doc.id: DailyActivity.fromMap(doc.id, doc.data()),
      };
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Unable to load your recent activity. Please try again.',
      );
    }
  }

  void _requireAuth(String userId) {
    if (userId.isEmpty) {
      throw const AuthException(message: 'User is not authenticated.');
    }
  }
}
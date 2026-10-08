import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/exceptions.dart';
import '../models/user_profile.dart';

/// Handles all Firestore operations for the user profile.
///
/// Keeps database logic out of the UI widgets. All access is scoped to the
/// currently authenticated user via their UID. No sensitive authentication
/// data (e.g. passwords) is ever persisted.
class ProfileService {
  final FirebaseFirestore? _injectedFirestore;

  ProfileService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  /// Lazily resolve the Firestore instance. Tests inject a fake instance.
  FirebaseFirestore get _firestore => _injectedFirestore ?? FirebaseFirestore.instance;

  /// Firestore path of a user's profile document.
  ///
  /// This is the single source of truth for the profile location and matches
  /// the `match /users/{userId}` Firestore rule, so the path is always scoped
  /// to the authenticated UID passed in.
  static String userDocPath(String uid) => 'users/$uid';

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.doc(userDocPath(uid));

  /// Get the profile document for the given [uid].
  /// Returns null if the document does not exist yet.
  Future<UserProfile?> getProfile(String uid) async {
    try {
      if (uid.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot = await _userDoc(uid).get();
      if (!snapshot.exists) {
        return null;
      }
      return UserProfile.fromMap(uid, snapshot.data() ?? const {});
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: _mapError(e));
    }
  }

  /// Create a new profile document. Fails safely if the document exists.
  Future<void> createProfile(UserProfile profile) async {
    try {
      await _userDoc(profile.uid).set(profile.toMap(includeTimestamps: true));
    } catch (e) {
      throw AppException(message: _mapError(e));
    }
  }

  /// Update the profile document with merge semantics so partial updates do
  /// not erase fields that were not edited.
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _userDoc(profile.uid).set(
        profile.toMap(),
        SetOptions(merge: true),
      );
      await _userDoc(profile.uid).update({'updatedAt': Timestamp.now()});
    } catch (e) {
      throw AppException(message: _mapError(e));
    }
  }

  /// Map Firestore errors to friendly, non-sensitive messages.
  String _mapError(Object error) {
    if (error is AppException) return error.message;
    final message = error.toString().toLowerCase();
    if (message.contains('permission-denied') ||
        message.contains('permission denied')) {
      return 'You do not have permission to access this profile.';
    }
    if (message.contains('unavailable') ||
        message.contains('network') ||
        message.contains('offline')) {
      return 'No internet connection. Please check your connection and try again.';
    }
    if (message.contains('not-found')) {
      return 'Profile not found.';
    }
    return 'Could not load or save your profile. Please try again.';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/exceptions.dart';
import '../models/medical_profile.dart';
import '../models/medical_record.dart';

/// Handles all Firestore operations for the EHR (medical records + medical
/// profile), keeping database logic out of the UI.
///
/// Records are stored under `users/{userId}/medical_records/{recordId}` and
/// the structured profile under `users/{userId}/medical_profile`, so each user
/// can only ever access their own medical data.
class MedicalRecordService {
  final FirebaseFirestore? _injectedFirestore;

  MedicalRecordService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  /// Lazily resolve the Firestore instance. Tests inject a fake instance.
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _recordsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('medical_records');

  // The structured profile is a single fixed document inside the
  // `medical_profile` subcollection so it never collides with the Phase 4
  // user-profile document (`users/{userId}`).
  DocumentReference<Map<String, dynamic>> _profileDoc(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('medical_profile')
          .doc('medical');

  /// Returns all medical records for [userId], newest first.
  Future<List<MedicalRecord>> getRecords(String userId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot = await _recordsCollection(userId)
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => MedicalRecord.fromMap(doc.id, doc.data()))
          .toList();
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _recordErrorMessage);
    }
  }

  /// Returns a single medical record for [userId].
  Future<MedicalRecord?> getRecord(String userId, String recordId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot = await _recordsCollection(userId).doc(recordId).get();
      if (!snapshot.exists) {
        return null;
      }
      return MedicalRecord.fromMap(snapshot.id, snapshot.data() ?? const {});
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _recordErrorMessage);
    }
  }

  /// Creates a new medical record and returns it with its generated id.
  Future<MedicalRecord> createRecord(MedicalRecord record) async {
    try {
      if (record.userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final docRef = _recordsCollection(record.userId).doc();
      final newId = docRef.id;
      await docRef.set(record.copyWith(id: newId).toMap(includeTimestamps: true));
      return record.copyWith(id: newId);
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _recordErrorMessage);
    }
  }

  /// Updates an existing record in place (same document) and refreshes
  /// [updatedAt].
  Future<void> updateRecord(MedicalRecord record) async {
    try {
      if (record.userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final updated = record.copyWith(updatedAt: DateTime.now());
      // merge semantics so untouched writable fields are never dropped.
      await _recordsCollection(record.userId)
          .doc(record.id)
          .set(updated.toMap(), SetOptions(merge: true));
      await _recordsCollection(record.userId)
          .doc(record.id)
          .update({'updatedAt': Timestamp.now()});
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _recordErrorMessage);
    }
  }

  /// Deletes a medical record. Only the owning user's record is reachable.
  Future<void> deleteRecord(String userId, String recordId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      await _recordsCollection(userId).doc(recordId).delete();
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _recordErrorMessage);
    }
  }

  /// Returns the user's structured medical profile (null when not created).
  Future<MedicalProfile?> getMedicalProfile(String userId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot = await _profileDoc(userId).get();
      if (!snapshot.exists) {
        return null;
      }
      return MedicalProfile.fromMap(userId, snapshot.data() ?? const {});
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _profileErrorMessage);
    }
  }

  /// Saves the medical profile with merge semantics.
  Future<void> saveMedicalProfile(MedicalProfile profile) async {
    try {
      if (profile.userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final updated = profile.copyWith(updatedAt: DateTime.now());
      await _profileDoc(profile.userId).set(
        updated.toMap(),
        SetOptions(merge: true),
      );
      await _profileDoc(profile.userId).update({'updatedAt': Timestamp.now()});
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _profileErrorMessage);
    }
  }

  static const _recordErrorMessage =
      'Unable to manage your medical records. Please try again.';
  static const _profileErrorMessage =
      'Unable to save your medical information. Please try again.';
}
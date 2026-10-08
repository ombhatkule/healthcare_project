import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/exceptions.dart';
import '../models/prescription.dart';

/// Handles all Firestore operations for prescriptions, keeping database logic
/// out of the UI.
///
/// Prescriptions are stored under `users/{userId}/prescriptions/
/// {prescriptionId}`, so each user can only ever access their own records.
class PrescriptionService {
  final FirebaseFirestore? _injectedFirestore;

  PrescriptionService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  /// Lazily resolve the Firestore instance. Tests inject a fake instance.
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _prescriptionsCollection(
          String userId) =>
      _firestore.collection('users').doc(userId).collection('prescriptions');

  /// Returns all prescriptions belonging to [userId], newest first.
  Future<List<Prescription>> getPrescriptions(String userId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot = await _prescriptionsCollection(userId)
          .orderBy('prescriptionDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Prescription.fromMap(doc.id, doc.data()))
          .toList();
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _prescriptionErrorMessage);
    }
  }

  /// Returns a single prescription for [userId].
  Future<Prescription?> getPrescription(
      String userId, String prescriptionId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot =
          await _prescriptionsCollection(userId).doc(prescriptionId).get();
      if (!snapshot.exists) {
        return null;
      }
      return Prescription.fromMap(snapshot.id, snapshot.data() ?? const {});
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _prescriptionErrorMessage);
    }
  }

  /// Creates a new prescription and returns it with its generated id.
  Future<Prescription> createPrescription(Prescription prescription) async {
    try {
      if (prescription.userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final docRef = _prescriptionsCollection(prescription.userId).doc();
      final newId = docRef.id;
      await docRef.set(
        prescription.copyWith(id: newId).toMap(includeTimestamps: true),
      );
      return prescription.copyWith(id: newId);
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _prescriptionErrorMessage);
    }
  }

  /// Updates an existing prescription in place (same document) and refreshes
  /// [updatedAt].
  Future<void> updatePrescription(Prescription prescription) async {
    try {
      if (prescription.userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final updated = prescription.copyWith(updatedAt: DateTime.now());
      // Merge semantics so untouched writable fields are never dropped.
      await _prescriptionsCollection(prescription.userId)
          .doc(prescription.id)
          .set(updated.toMap(), SetOptions(merge: true));
      await _prescriptionsCollection(prescription.userId)
          .doc(prescription.id)
          .update({'updatedAt': Timestamp.now()});
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _prescriptionErrorMessage);
    }
  }

  /// Deletes a prescription. Only the owning user's record is reachable.
  Future<void> deletePrescription(String userId, String prescriptionId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      await _prescriptionsCollection(userId)
          .doc(prescriptionId)
          .delete();
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(message: _prescriptionErrorMessage);
    }
  }

  static const _prescriptionErrorMessage =
      'Unable to manage your prescriptions. Please try again.';
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/exceptions.dart';
import '../models/appointment_model.dart';

/// Represents a time conflict when a slot is already booked.
class BookingConflictException extends AppException {
  const BookingConflictException()
      : super(message: 'This time slot is no longer available.');
}

/// Handles all Firestore operations for user appointments.
///
/// Appointments are stored under `users/{userId}/appointments/{appointmentId}`
/// so each user can only ever access their own records.
class AppointmentService {
  final FirebaseFirestore? _injectedFirestore;

  AppointmentService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  /// Lazily resolve the Firestore instance. Tests inject a fake instance.
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _appointmentsCollection(
          String userId) =>
      _firestore.collection('users').doc(userId).collection('appointments');

  /// Creates a new appointment.
  ///
  /// Before writing, checks whether the same doctor/date/time slot has already
  /// been taken (double-booking guard). Throws [BookingConflictException] when
  /// the slot is no longer free.
  Future<AppointmentModel> bookAppointment(AppointmentModel appointment) async {
    try {
      if (appointment.userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }

      final collection = _appointmentsCollection(appointment.userId);

      // Double-booking check: same doctor/date/time slot (excluding cancelled
      // records). This deliberately uses only a single-field range query on
      // `appointmentDate`, which relies exclusively on auto-created indexes and
      // completes on any Firestore project (and the emulator). The extra
      // doctor / time / status filters are applied in memory over the user's
      // own small daily subcollection instead of a compound query that would
      // require a manually-created composite index and could leave the caller
      // waiting indefinitely.
      final startOfDay = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final daySnapshot = await collection
          .where('appointmentDate', isGreaterThanOrEqualTo: startOfDay)
          .where('appointmentDate', isLessThan: endOfDay)
          .limit(50)
          .get();

      final slotTaken = daySnapshot.docs.any((doc) {
        final data = doc.data();
        return data['doctorId'] == appointment.doctorId &&
            data['appointmentTime'] == appointment.appointmentTime &&
            data['status'] != 'cancelled';
      });

      if (slotTaken) {
        throw const BookingConflictException();
      }

      final docRef = collection.doc();
      final newId = docRef.id;
      await docRef.set(appointment.copyWith(id: newId).toMap());
      return appointment.copyWith(id: newId);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: _mapError(e));
    }
  }

  /// Returns all appointments belonging to [userId], sorted newest first.
  Future<List<AppointmentModel>> getAppointments(String userId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot = await _appointmentsCollection(userId)
          .orderBy('appointmentDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.id, doc.data()))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: _mapError(e));
    }
  }

  /// Returns a single appointment by [appointmentId] for [userId].
  Future<AppointmentModel?> getAppointment(
      String userId, String appointmentId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      final snapshot =
          await _appointmentsCollection(userId).doc(appointmentId).get();
      if (!snapshot.exists) {
        return null;
      }
      return AppointmentModel.fromMap(snapshot.id, snapshot.data() ?? const {});
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: _mapError(e));
    }
  }

  /// Cancels an appointment by updating its status to `cancelled`.
  ///
  /// The record is kept (not deleted) so it remains in appointment history.
  Future<void> cancelAppointment(String userId, String appointmentId) async {
    try {
      if (userId.isEmpty) {
        throw const AuthException(message: 'User is not authenticated.');
      }
      await _appointmentsCollection(userId).doc(appointmentId).update({
        'status': 'cancelled',
      });
    } on AppException {
      rethrow;
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
      return 'You do not have permission to access these appointments.';
    }
    if (message.contains('unavailable') ||
        message.contains('network') ||
        message.contains('offline')) {
      return 'No internet connection. Please check your connection and try again.';
    }
    if (message.contains('not-found')) {
      return 'Appointment not found.';
    }
    return 'Unable to manage your appointments. Please try again.';
  }
}
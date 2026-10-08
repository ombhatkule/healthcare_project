import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';

/// State management for appointments.
///
/// Loads the authenticated user's appointments from Firestore and exposes
/// booking / cancellation operations. Business logic lives in
/// [AppointmentService]; this controller only owns UI-facing state.
class AppointmentController extends ChangeNotifier {
  final AppointmentService _service;

  AppointmentController(this._service);

  List<AppointmentModel> _appointments = [];
  AppointmentModel? _selectedAppointment;
  bool _isLoading = false;
  bool _isBooking = false;
  bool _isCancelling = false;
  String? _errorMessage;

  List<AppointmentModel> get appointments => List.unmodifiable(_appointments);
  AppointmentModel? get selectedAppointment => _selectedAppointment;
  bool get isLoading => _isLoading;
  bool get isBooking => _isBooking;
  bool get isCancelling => _isCancelling;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Appointments that are upcoming (confirmed or pending).
  List<AppointmentModel> get upcomingAppointments {
    return _appointments.where((a) => a.isUpcoming).toList();
  }

  /// Appointments that are past (completed).
  List<AppointmentModel> get pastAppointments {
    return _appointments
        .where((a) => a.status == AppointmentStatus.completed)
        .toList();
  }

  /// Appointments that were cancelled.
  List<AppointmentModel> get cancelledAppointments {
    return _appointments
        .where((a) => a.status == AppointmentStatus.cancelled)
        .toList();
  }

  /// Loads all appointments for the authenticated [userId].
  Future<void> loadAppointments(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _appointments = await _service.getAppointments(userId);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Unable to load your appointments. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches a single appointment by [appointmentId] for [userId].
  Future<bool> loadAppointment(String userId, String appointmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selectedAppointment =
          await _service.getAppointment(userId, appointmentId);
      return _selectedAppointment != null;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to load the appointment. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Books [appointment]. Returns the saved appointment on success.
  ///
  /// Returns null and sets [errorMessage] when booking fails (including slot
  /// conflict handled by [AppointmentService]).
  Future<AppointmentModel?> book(
      AppointmentModel appointment) async {
    _isBooking = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Guard against a Firestore call that never completes (e.g. network
      // issues or a backend that never responds). Without this, `_isBooking`
      // would stay true forever and the confirm button would keep spinning.
      final saved = await _service
          .bookAppointment(appointment)
          .timeout(const Duration(seconds: 20));
      _appointments = [saved, ..._appointments];
      return saved;
    } on TimeoutException {
      _errorMessage =
          'Booking is taking too long. Please check your connection and try again.';
      return null;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (_) {
      _errorMessage = 'Unable to book the appointment. Please try again.';
      return null;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }

  /// Cancels the appointment with [appointmentId] for [userId].
  /// Returns true on success.
  Future<bool> cancel(String userId, String appointmentId) async {
    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.cancelAppointment(userId, appointmentId);
      // Refresh local state so the status is updated immediately.
      final index =
          _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index]
            .copyWith(status: AppointmentStatus.cancelled);
        _appointments = List.of(_appointments);
      }
      if (_selectedAppointment?.id == appointmentId) {
        _selectedAppointment = _selectedAppointment
            ?.copyWith(status: AppointmentStatus.cancelled);
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to cancel the appointment. Please try again.';
      return false;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
import 'package:healthcare_app/features/appointment_booking/models/appointment_model.dart';
import 'package:healthcare_app/features/appointment_booking/services/appointment_service.dart';
import 'package:healthcare_app/shared/enums/appointment_status.dart';

/// A fake [AppointmentService] for widget/unit tests that avoids the real
/// Firestore SDK.
///
/// Optionally enforces the same double-booking guard as the real service so
/// conflict-handling can be tested without a backend.
class FakeAppointmentService extends AppointmentService {
  FakeAppointmentService({
    List<AppointmentModel> initial = const [],
    this.enforceConflicts = false,
  }) : _appointments = List.of(initial);

  final List<AppointmentModel> _appointments;
  final bool enforceConflicts;

  @override
  Future<List<AppointmentModel>> getAppointments(String userId) async {
    return _appointments.where((a) => a.userId == userId).toList();
  }

  @override
  Future<AppointmentModel?> getAppointment(
      String userId, String appointmentId) async {
    for (final appointment in _appointments) {
      if (appointment.id == appointmentId && appointment.userId == userId) {
        return appointment;
      }
    }
    return null;
  }

  @override
  Future<AppointmentModel> bookAppointment(AppointmentModel appointment) async {
    if (enforceConflicts) {
      final conflict = _appointments.any(
        (a) =>
            a.doctorId == appointment.doctorId &&
            a.status != AppointmentStatus.cancelled &&
            a.appointmentDate.year == appointment.appointmentDate.year &&
            a.appointmentDate.month == appointment.appointmentDate.month &&
            a.appointmentDate.day == appointment.appointmentDate.day &&
            a.appointmentTime == appointment.appointmentTime,
      );
      if (conflict) {
        throw const BookingConflictException();
      }
    }
    final saved = appointment.copyWith(
      id: 'appt-${_appointments.length + 1}',
    );
    _appointments.add(saved);
    return saved;
  }

  @override
  Future<void> cancelAppointment(
      String userId, String appointmentId) async {
    final index =
        _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _appointments[index] =
          _appointments[index].copyWith(status: AppointmentStatus.cancelled);
    }
  }
}
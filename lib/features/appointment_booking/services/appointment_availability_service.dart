import '../models/appointment_model.dart';

/// Contract for doctor availability lookups.
///
/// Currently backed by [MockAppointmentAvailabilityService]. Swapping in a real
/// backend only requires a new implementation of this interface and changing
/// the injection point in `main.dart`.
abstract class AppointmentAvailabilityService {
  /// Returns the time slots available for [doctorId] on [date].
  ///
  /// Slots are returned as [TimeOfDayValue] in 24-hour terms. The list does
  /// not take already-booked appointments into account — that conflict check
  /// happens at confirmation time via [AppointmentService].
  Future<List<TimeOfDayValue>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  });
}
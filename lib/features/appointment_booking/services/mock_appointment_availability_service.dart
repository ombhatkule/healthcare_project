import '../models/appointment_model.dart';
import 'appointment_availability_service.dart';

/// Local/mock doctor availability.
///
/// IMPORTANT: These slots are NOT real doctor availability. They are generated
/// deterministically for UI development so the booking flow behaves like the
/// real product. Replace this implementation (and the injection point in
/// `main.dart`) with a real backend when one is available.
class MockAppointmentAvailabilityService
    implements AppointmentAvailabilityService {
  /// Clinic hours used by the mock: 10:00 AM – 06:00 PM, 30-minute slots.
  static const int _startHour = 10;
  static const int _endHour = 18;

  /// Lunch gap where no slots exist (slots are not offered).
  static const int _lunchStartHour = 12;

  /// Percentage of slots randomly withheld to mimic a busy schedule.
  static const double _busyRatio = 0.35;

  @override
  Future<List<TimeOfDayValue>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    // Simulate network latency so loading states are exercised.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final slots = <TimeOfDayValue>[];
    for (var hour = _startHour; hour < _endHour; hour++) {
      for (final minute in const [0, 30]) {
        if (hour >= _lunchStartHour && hour < _lunchStartHour + 2) {
          continue; // lunch break
        }
        final slot = TimeOfDayValue(hour: hour, minute: minute);
        if (!_isBusy(doctorId, date, slot)) {
          slots.add(slot);
        }
      }
    }
    return slots;
  }

  /// Deterministic pseudo-random "is this slot taken" decision based on the
  /// doctor, date and slot, so results are stable across rebuilds but differ
  /// between days/doctors.
  bool _isBusy(String doctorId, DateTime date, TimeOfDayValue slot) {
    final seed = doctorId.hashCode ^
        date.year.hashCode ^
        date.month.hashCode ^
        date.day.hashCode ^
        slot.hour ^
        (slot.minute << 5);
    final value = (seed.abs() % 100) / 100.0;
    return value < _busyRatio;
  }
}
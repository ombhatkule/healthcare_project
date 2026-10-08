import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/appointment_booking/services/mock_appointment_availability_service.dart';

void main() {
  final service = MockAppointmentAvailabilityService();

  test('returns slots within clinic hours and never during lunch', () async {
    final slots = await service.getAvailableSlots(
      doctorId: 'doc-1',
      date: DateTime(2026, 9, 18),
    );

    expect(slots, isNotEmpty);
    for (final slot in slots) {
      expect(slot.hour, inInclusiveRange(10, 17));
      expect(slot.minute, anyOf(0, 30));
      // Lunch break (12:00 - 14:00) never offers slots.
      expect(slot.hour < 12 || slot.hour >= 14, isTrue,
          reason: 'Slot ${slot.formatted} falls inside the lunch break.');
    }
  });

  test('is deterministic for the same doctor and date', () async {
    final date = DateTime(2026, 9, 18);
    final first = await service.getAvailableSlots(doctorId: 'doc-1', date: date);
    final second =
        await service.getAvailableSlots(doctorId: 'doc-1', date: date);
    expect(first.map((s) => s.formatted), second.map((s) => s.formatted));
  });

  test('differs between dates and between doctors', () async {
    final dayOne = await service.getAvailableSlots(
        doctorId: 'doc-1', date: DateTime(2026, 9, 18));
    final dayTwo = await service.getAvailableSlots(
        doctorId: 'doc-1', date: DateTime(2026, 9, 19));
    final otherDoctor = await service.getAvailableSlots(
        doctorId: 'doc-2', date: DateTime(2026, 9, 18));

    final one = dayOne.map((s) => s.formatted).toList();
    final two = dayTwo.map((s) => s.formatted).toList();
    final three = otherDoctor.map((s) => s.formatted).toList();

    final allSame = one.length == two.length &&
        two.length == three.length &&
        one.join() == two.join() &&
        two.join() == three.join();
    expect(allSame, isFalse,
        reason: 'Availability should vary across days/doctors.');
  });

  test('each slot is formatted as a valid 12-hour label', () async {
    final slots = await service.getAvailableSlots(
      doctorId: 'doc-1',
      date: DateTime(2026, 9, 20),
    );
    for (final slot in slots) {
      expect(slot.formatted, matches(RegExp(r'^\d{2}:\d{2} (AM|PM)$')));
    }
  });
}
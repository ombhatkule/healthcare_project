import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/errors/exceptions.dart';
import 'package:healthcare_app/features/appointment_booking/models/appointment_model.dart';
import 'package:healthcare_app/features/appointment_booking/presentation/providers/appointment_controller.dart';
import 'package:healthcare_app/features/appointment_booking/services/appointment_service.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/doctor.dart';
import 'package:healthcare_app/shared/enums/appointment_status.dart';
import 'fake_appointment_service.dart';

void main() {
  const sampleDoctor = Doctor(
    id: 'doc-1',
    name: 'Dr. Test Doctor',
    specialty: 'Cardiologist',
    qualification: 'MBBS, MD',
    experienceYears: 10,
    hospital: 'Test Hospital',
    location: 'Pune',
    consultationFee: 500,
    rating: 4.5,
    reviewCount: 20,
    availableToday: true,
  );

  AppointmentModel appointmentFor(
    DateTime date,
    String time, {
    String doctorId = 'doc-1',
  }) {
    return AppointmentModel(
      id: '',
      userId: 'user-1',
      doctorId: doctorId,
      doctorName: sampleDoctor.name,
      specialty: sampleDoctor.specialty,
      hospital: sampleDoctor.hospital,
      location: sampleDoctor.location,
      appointmentDate: date,
      appointmentTime: time,
      status: AppointmentStatus.confirmed,
      consultationFee: 500,
      createdAt: DateTime(2026, 9, 11),
    );
  }

  test('controller loads appointments for the user', () async {
    final existing = appointmentFor(DateTime(2026, 9, 18), '10:00 AM')
        .copyWith(id: 'existing-1');
    final service = FakeAppointmentService(initial: [existing]);
    final controller = AppointmentController(service);

    await controller.loadAppointments('user-1');

    expect(controller.isLoading, isFalse);
    expect(controller.appointments, hasLength(1));
    expect(controller.appointments.first.id, 'existing-1');
    expect(controller.upcomingAppointments, hasLength(1));
  });

  test('booking an identical doctor/date/time slot is rejected', () async {
    final existing = appointmentFor(DateTime(2026, 9, 18), '10:00 AM')
        .copyWith(id: 'existing-1');
    final service = FakeAppointmentService(
      initial: [existing],
      enforceConflicts: true,
    );
    final controller = AppointmentController(service);

    final duplicate = appointmentFor(DateTime(2026, 9, 18), '10:00 AM');
    final result = await controller.book(duplicate);

    expect(result, isNull);
    expect(controller.errorMessage, contains('no longer available'));
    // The fake is not silently overwritten.
    expect(service.getAppointments('user-1'),
        completion(hasLength(1)));
  });

  test('booking the same slot is allowed after it was cancelled', () async {
    final cancelled = appointmentFor(DateTime(2026, 9, 18), '10:00 AM')
        .copyWith(id: 'old-1', status: AppointmentStatus.cancelled);
    final service = FakeAppointmentService(
      initial: [cancelled],
      enforceConflicts: true,
    );
    final controller = AppointmentController(service);

    final rebooked = await controller.book(
      appointmentFor(DateTime(2026, 9, 18), '10:00 AM'),
    );

    expect(rebooked, isNotNull);
    expect(rebooked!.id, isNotEmpty);
  });

  test('booking a different time on the same day is allowed', () async {
    final existing = appointmentFor(DateTime(2026, 9, 18), '10:00 AM')
        .copyWith(id: 'existing-1');
    final service = FakeAppointmentService(
      initial: [existing],
      enforceConflicts: true,
    );
    final controller = AppointmentController(service);

    final other = appointmentFor(DateTime(2026, 9, 18), '11:00 AM');
    final result = await controller.book(other);

    expect(result, isNotNull);
  });

  test('cancellation keeps the record and changes status to cancelled',
      () async {
    final existing = appointmentFor(DateTime(2026, 9, 18), '10:00 AM')
        .copyWith(id: 'a-1');
    final service = FakeAppointmentService(initial: [existing]);
    final controller = AppointmentController(service);
    await controller.loadAppointments('user-1');

    final ok = await controller.cancel('user-1', 'a-1');

    expect(ok, isTrue);
    expect(controller.appointments.first.status, AppointmentStatus.cancelled);
    expect(controller.cancelledAppointments, hasLength(1));
    expect(controller.upcomingAppointments, isEmpty);
    // Record remains available for history.
    final stored = await service.getAppointment('user-1', 'a-1');
    expect(stored, isNotNull);
    expect(stored!.status, AppointmentStatus.cancelled);
  });

  test('loadAppointment retrieves a single record', () async {
    final existing = appointmentFor(DateTime(2026, 9, 18), '10:00 AM')
        .copyWith(id: 'a-1');
    final service = FakeAppointmentService(initial: [existing]);
    final controller = AppointmentController(service);
    await controller.loadAppointments('user-1');

    final found = await controller.loadAppointment('user-1', 'a-1');
    expect(found, isTrue);
    expect(controller.selectedAppointment?.id, 'a-1');
  });

  test('double booking guard surfaces the conflict as a friendly message',
      () {
    const conflict = BookingConflictException();
    expect(conflict.message, contains('no longer available'));
  });

  test('load failures surface as friendly error messages', () async {
    final service = _FailingAppointmentService();
    final controller = AppointmentController(service);

    await controller.loadAppointments('user-1');

    expect(controller.hasError, isTrue);
    expect(controller.errorMessage, isNotEmpty);
    expect(controller.errorMessage, isNot(contains('Exception')));
  });
}

/// A service that always fails like a network/backend error.
class _FailingAppointmentService extends FakeAppointmentService {
  @override
  Future<List<AppointmentModel>> getAppointments(String userId) async {
    throw AppException(message: 'Unable to load your appointments.');
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/appointment_booking/models/appointment_model.dart';
import 'package:healthcare_app/shared/enums/appointment_status.dart';

void main() {
  final appointmentDate = DateTime(2026, 9, 18);

  AppointmentModel buildAppointment({
    AppointmentStatus status = AppointmentStatus.confirmed,
  }) {
    return AppointmentModel(
      id: 'appt-1',
      userId: 'user-1',
      doctorId: 'doc-1',
      doctorName: 'Dr. Sarah Chen',
      specialty: 'Cardiologist',
      hospital: 'Apollo Hospital',
      location: 'Pune',
      appointmentDate: appointmentDate,
      appointmentTime: '10:30 AM',
      status: status,
      reasonForVisit: 'Routine consultation',
      notes: 'Bring past reports',
      consultationFee: 500,
      createdAt: DateTime(2026, 9, 11),
    );
  }

  test('fromMap/toMap round-trips all fields', () {
    final appointment = buildAppointment();
    final map = appointment.toMap();
    final restored = AppointmentModel.fromMap('appt-1', map);

    expect(restored.id, 'appt-1');
    expect(restored.userId, 'user-1');
    expect(restored.doctorId, 'doc-1');
    expect(restored.doctorName, 'Dr. Sarah Chen');
    expect(restored.specialty, 'Cardiologist');
    expect(restored.hospital, 'Apollo Hospital');
    expect(restored.location, 'Pune');
    expect(restored.appointmentDate, appointmentDate);
    expect(restored.appointmentTime, '10:30 AM');
    expect(restored.status, AppointmentStatus.confirmed);
    expect(restored.reasonForVisit, 'Routine consultation');
    expect(restored.notes, 'Bring past reports');
    expect(restored.consultationFee, 500);
  });

  test('fromMap reads Timestamp appointmentDate/createdAt', () {
    final restored = AppointmentModel.fromMap(
      'appt-1',
      {
        'userId': 'user-1',
        'doctorId': 'doc-1',
        'doctorName': 'Dr. Sarah Chen',
        'specialty': 'Cardiologist',
        'hospital': 'Apollo Hospital',
        'location': 'Pune',
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'appointmentTime': '10:30 AM',
        'status': 'confirmed',
        'reasonForVisit': '',
        'notes': '',
        'consultationFee': 500,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 11)),
      },
    );

    expect(restored.appointmentDate, appointmentDate);
    expect(restored.status, AppointmentStatus.confirmed);
  });

  test('unknown status falls back to pending', () {
    final restored = AppointmentModel.fromMap('appt-1', {
      'userId': 'u',
      'doctorId': 'd',
      'doctorName': 'Dr. X',
      'specialty': 'GP',
      'hospital': 'H',
      'location': 'L',
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': '10:00 AM',
      'status': 'unknown-status',
    });

    expect(restored.status, AppointmentStatus.pending);
  });

  test('isUpcoming is true for confirmed and pending, false otherwise', () {
    expect(buildAppointment(status: AppointmentStatus.confirmed).isUpcoming, isTrue);
    expect(buildAppointment(status: AppointmentStatus.pending).isUpcoming, isTrue);
    expect(buildAppointment(status: AppointmentStatus.cancelled).isUpcoming, isFalse);
    expect(buildAppointment(status: AppointmentStatus.completed).isUpcoming, isFalse);
  });

  test('statusLabel returns human-readable values', () {
    expect(buildAppointment(status: AppointmentStatus.confirmed).statusLabel, 'Confirmed');
    expect(buildAppointment(status: AppointmentStatus.pending).statusLabel, 'Pending');
    expect(buildAppointment(status: AppointmentStatus.completed).statusLabel, 'Completed');
    expect(buildAppointment(status: AppointmentStatus.cancelled).statusLabel, 'Cancelled');
  });

  test('time getter parses 12-hour strings into TimeOfDayValue', () {
    final morning = buildAppointment().copyWith(appointmentTime: '09:30 AM');
    expect(morning.time.formatted, '09:30 AM');

    final noon = buildAppointment().copyWith(appointmentTime: '12:00 PM');
    expect(noon.time.hour, 12);

    final evening = buildAppointment().copyWith(appointmentTime: '02:30 PM');
    expect(evening.time.hour, 14);
    expect(evening.time.formatted, '02:30 PM');
  });

  test('copyWith preserves other fields and changes only the given ones', () {
    final appointment = buildAppointment();
    final updated = appointment.copyWith(status: AppointmentStatus.cancelled);

    expect(updated.status, AppointmentStatus.cancelled);
    expect(updated.doctorName, appointment.doctorName);
    expect(updated.appointmentDate, appointment.appointmentDate);
    expect(updated.id, appointment.id);
  });
}
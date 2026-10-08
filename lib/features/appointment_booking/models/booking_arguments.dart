import '../../doctor_recommendation/models/doctor.dart';

/// Arguments handed to the Appointment Booking screen.
///
/// Carries the actual doctor selected from Doctor Details / Search /
/// Recommendation so the booking flow always uses the consistent doctor.
class BookingArguments {
  final Doctor doctor;

  const BookingArguments({required this.doctor});
}

/// Arguments handed to the Appointment Details screen.
class AppointmentDetailsArguments {
  final String appointmentId;

  const AppointmentDetailsArguments({required this.appointmentId});
}

/// Arguments handed to the Appointment Confirmation screen.
class AppointmentConfirmationArguments {
  final String appointmentId;

  const AppointmentConfirmationArguments({required this.appointmentId});
}
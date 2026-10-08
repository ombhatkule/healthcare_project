import '../../appointment_booking/models/appointment_model.dart';
import '../../../shared/enums/appointment_status.dart';
import 'health_summary_model.dart';

/// Provides **mock** data for the Phase 3 dashboard preview.
///
/// IMPORTANT: This data is clearly separated from real Firebase data and is
/// intended for UI development only. It will be replaced by Firestore-backed
/// repositories in later phases. It is NOT real patient data.
abstract final class MockDashboardData {
  /// The upcoming appointment shown on the dashboard.
  ///
  /// Set to [null] by default so the "no appointment" empty state is shown.
  /// Swap in [sampleUpcomingAppointments] to preview a populated card.
  static AppointmentModel? get upcomingAppointment => null;

  /// A sample health summary used as placeholder content.
  static HealthSummaryModel get healthSummary => const HealthSummaryModel(
        bmi: 22.4,
        medicalRecordsCount: 0,
      );

  /// A sample upcoming appointment used to preview the populated card.
  static AppointmentModel get sampleAppointment => AppointmentModel(
        id: 'mock-1',
        userId: '',
        doctorId: 'mock-doctor',
        doctorName: 'Dr. Sarah Chen',
        specialty: 'Cardiology',
        hospital: 'Example Hospital',
        location: 'Pune',
        appointmentDate: DateTime(2026, 9, 10),
        appointmentTime: '10:30 AM',
        status: AppointmentStatus.confirmed,
        createdAt: DateTime(2026, 9, 1),
      );
}

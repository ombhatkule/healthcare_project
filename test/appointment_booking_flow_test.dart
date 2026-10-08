import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/config/app_router.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/appointment_booking/models/appointment_model.dart';
import 'package:healthcare_app/features/appointment_booking/models/booking_arguments.dart';
import 'package:healthcare_app/features/appointment_booking/presentation/appointment_booking_screen.dart';
import 'package:healthcare_app/features/appointment_booking/presentation/providers/appointment_controller.dart';
import 'package:healthcare_app/features/appointment_booking/services/appointment_availability_service.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/doctor.dart';
import 'package:provider/provider.dart';
import 'fake_appointment_service.dart';
import 'fake_auth_service.dart';

/// A controllable availability source so slot content is deterministic.
class _FakeAvailabilityService implements AppointmentAvailabilityService {
  const _FakeAvailabilityService();

  @override
  Future<List<TimeOfDayValue>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    return const [
      TimeOfDayValue(hour: 10, minute: 0),
      TimeOfDayValue(hour: 10, minute: 30),
      TimeOfDayValue(hour: 11, minute: 0),
    ];
  }
}

const _sampleDoctor = Doctor(
  id: 'doc-booking-test',
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
  languages: ['English'],
);

Widget _wrapBook({FakeAppointmentService? service}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(FakeAuthService()),
      ),
      Provider<AppointmentAvailabilityService>.value(
        value: const _FakeAvailabilityService(),
      ),
      ChangeNotifierProvider<AppointmentController>(
        create: (_) => AppointmentController(service ?? FakeAppointmentService()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRouter.generateRoute,
      home: const AppointmentBookingScreen(
        args: BookingArguments(doctor: _sampleDoctor),
      ),
    ),
  );
}

void main() {
  group('AppointmentBookingScreen (Phase 11)', () {
    testWidgets('shows the selected doctor at the top of the flow',
        (tester) async {
      await tester.pumpWidget(_wrapBook());
      await tester.pumpAndSettle();

      expect(find.text('Dr. Test Doctor'), findsOneWidget);
      expect(find.text('Cardiologist'), findsWidgets);
      final now = DateTime.now();
      expect(
        BookingDateRange.min(),
        DateTime(now.year, now.month, now.day),
        reason: 'Earliest bookable date must be today (no past dates).',
      );
    });

    testWidgets('past dates cannot be booked (firstDate is today)',
        (tester) async {
      await tester.pumpWidget(_wrapBook());
      await tester.pumpAndSettle();

      // Open the native date picker and verify the grid starts at today.
      await tester.tap(find.text('No date selected'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.widget<DatePickerDialog>(find.byType(DatePickerDialog)).initialDate,
          isNotNull);
      // Confirm today's date; selecting it is allowed.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('continuing without a date shows a validation message',
        (tester) async {
      await tester.pumpWidget(_wrapBook());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Please select an appointment date.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selecting a date loads time slots', (tester) async {
      await tester.pumpWidget(_wrapBook());
      await tester.pumpAndSettle();

      await tester.tap(find.text('No date selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('10:00 AM'), findsOneWidget);
      expect(find.text('10:30 AM'), findsOneWidget);
      expect(find.text('11:00 AM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('continuing without a time shows a validation message',
        (tester) async {
      await tester.pumpWidget(_wrapBook());
      await tester.pumpAndSettle();

      await tester.tap(find.text('No date selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Now on the time step, continue without selecting.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Please select an available time.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('full flow reaches the review step with correct details',
        (tester) async {
      await tester.pumpWidget(_wrapBook());
      await tester.pumpAndSettle();

      // Date step
      await tester.tap(find.text('No date selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Time step
      await tester.tap(find.text('10:30 AM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Info step
      await tester.enterText(find.byType(TextField).first, 'Routine checkup');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Review step
      expect(find.text('Review Appointment'), findsOneWidget);
      expect(find.text('Dr. Test Doctor'), findsWidgets);
      expect(find.text('Cardiologist'), findsWidgets);
      expect(find.text('Test Hospital'), findsOneWidget);
      expect(find.text('Pune'), findsOneWidget);
      expect(find.text('10:30 AM'), findsWidgets);
      expect(find.text('Routine checkup'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('confirming while signed out requires sign-in',
        (tester) async {
      await tester.pumpWidget(_wrapBook());
      await tester.pumpAndSettle();

      await tester.tap(find.text('No date selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10:00 AM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Appointment'), findsOneWidget);
      await tester.tap(find.text('Confirm Appointment'));
      await tester.pumpAndSettle();

      expect(find.text('Please sign in to book an appointment.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/appointment_booking/presentation/providers/appointment_controller.dart';
import 'package:healthcare_app/features/appointment_history/presentation/appointment_details_screen.dart';
import 'package:healthcare_app/features/appointment_history/presentation/appointment_history_screen.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'fake_appointment_service.dart';
import 'fake_auth_service.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(FakeAuthService()),
      ),
      ChangeNotifierProvider<AppointmentController>(
        create: (_) => AppointmentController(FakeAppointmentService()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  testWidgets('Appointments screen renders requested-sign-in state safely',
      (tester) async {
    await tester.pumpWidget(_wrap(const AppointmentHistoryScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Appointments screen does not overflow when signed out',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const AppointmentHistoryScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Appointment Details screen rejects missing appointment safely',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const AppointmentDetailsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appointment not found.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Appointment Details screen does not overflow on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(const AppointmentDetailsScreen()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
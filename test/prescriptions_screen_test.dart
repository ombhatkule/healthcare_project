import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_app/features/prescriptions/presentation/prescriptions_screen.dart';
import 'package:healthcare_app/features/prescriptions/presentation/providers/prescriptions_controller.dart';
import 'package:provider/provider.dart';

import 'fake_auth_service.dart';
import 'fake_prescription_service.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(FakeAuthService()),
      ),
      ChangeNotifierProvider<PrescriptionsController>(
        create: (_) => PrescriptionsController(FakePrescriptionService()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  testWidgets('Prescriptions screen renders empty state when signed out',
      (tester) async {
    await tester.pumpWidget(_wrap(const PrescriptionsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No prescriptions yet.'), findsOneWidget);
    expect(find.text('Add Prescription'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prescriptions screen does not overflow on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const PrescriptionsScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prescriptions screen does not overflow on very small screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const PrescriptionsScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prescriptions screen shows Add Prescription button',
      (tester) async {
    await tester.pumpWidget(_wrap(const PrescriptionsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Add Prescription'), findsOneWidget);
  });

  testWidgets('Tapping Add while signed out shows sign-in message',
      (tester) async {
    await tester.pumpWidget(_wrap(const PrescriptionsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Prescription'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please sign in to add a prescription.'),
      findsOneWidget,
    );
  });
}
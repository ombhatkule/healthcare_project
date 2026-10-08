import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_app/features/prescriptions/presentation/prescription_details_screen.dart';
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
  testWidgets('Prescription Details rejects a missing prescription safely',
      (tester) async {
    await tester.pumpWidget(_wrap(const PrescriptionDetailsScreen()));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load your prescriptions. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prescription Details does not overflow on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const PrescriptionDetailsScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prescription Details shows retry action when load fails',
      (tester) async {
    await tester.pumpWidget(_wrap(const PrescriptionDetailsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
  });
}
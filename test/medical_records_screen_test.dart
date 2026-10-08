import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_app/features/medical_records/presentation/providers/medical_records_controller.dart';
import 'package:healthcare_app/features/medical_records/presentation/medical_records_screen.dart';
import 'package:provider/provider.dart';

import 'fake_auth_service.dart';
import 'fake_medical_record_service.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(FakeAuthService()),
      ),
      ChangeNotifierProvider<MedicalRecordsController>(
        create: (_) => MedicalRecordsController(FakeMedicalRecordService()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  testWidgets('Medical Records screen renders empty state when signed out',
      (tester) async {
    await tester.pumpWidget(_wrap(const MedicalRecordsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No medical records yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Medical Records screen does not overflow on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const MedicalRecordsScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Medical Records screen shows Add Medical Record button',
      (tester) async {
    await tester.pumpWidget(_wrap(const MedicalRecordsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Add Medical Record'), findsOneWidget);
  });

  testWidgets('Medical Records screen shows sign-in message when signed out',
      (tester) async {
    await tester.pumpWidget(_wrap(const MedicalRecordsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No medical records yet.'), findsOneWidget);
  });
}
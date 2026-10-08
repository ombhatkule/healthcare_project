import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/config/app_router.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_app/features/doctor_recommendation/services/doctor_recommendation_service.dart';
import 'package:healthcare_app/features/doctor_recommendation/services/mock_doctor_repository.dart';
import 'package:healthcare_app/features/prescriptions/presentation/prescription_form_screen.dart';
import 'package:healthcare_app/features/prescriptions/presentation/providers/prescriptions_controller.dart';
import 'package:provider/provider.dart';

import 'fake_auth_service.dart';
import 'fake_prescription_service.dart';

Widget _wrap(Widget child) {
  final service = MockDoctorRepository();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(FakeAuthService()),
      ),
      ChangeNotifierProvider<PrescriptionsController>(
        create: (_) => PrescriptionsController(FakePrescriptionService()),
      ),
      Provider<DoctorRecommendationService>.value(value: service),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
      onGenerateRoute: AppRouter.generateRoute,
    ),
  );
}

void main() {
  testWidgets('Prescription form validates a required doctor name',
      (tester) async {
    await tester.pumpWidget(_wrap(const PrescriptionFormScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('prescriptionSubmitButton')));
    await tester.tap(find.byKey(const Key('prescriptionSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter the doctor name.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prescription form does not overflow on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const PrescriptionFormScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Picking a doctor from the catalog fills the doctor field',
      (tester) async {
    await tester.pumpWidget(_wrap(const PrescriptionFormScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pick Doctor').first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Narrow the search within the sheet, then select the doctor.
    await tester.enterText(
        find.byType(TextField).last, 'Aarti');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Aarti Sharma'), findsOneWidget);
    await tester.tap(find.text('Dr. Aarti Sharma'));
    await tester.pumpAndSettle();

    // The doctor name field now holds the selected doctor's name.
    final firstField =
        tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(firstField.controller?.text, 'Dr. Aarti Sharma');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Adding a medicine shows it in the list; remove clears it',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const PrescriptionFormScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Medicine'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('medicineNameField')), 'Paracetamol');
    await tester.tap(find.byKey(const Key('medicineSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.text('Medicines (1)'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Paracetamol'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
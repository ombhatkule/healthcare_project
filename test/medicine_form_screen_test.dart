import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/prescriptions/models/models.dart';
import 'package:healthcare_app/features/prescriptions/presentation/medicine_form_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: child,
    onGenerateRoute: (settings) {
      if (settings.name == '/medicine-form-test') {
        final args = settings.arguments as MedicineFormArguments?;
        return MaterialPageRoute<Medicine>(
          builder: (_) => MedicineFormScreen(args: args),
        );
      }
      return MaterialPageRoute(builder: (_) => const Scaffold());
    },
  );
}

void main() {
  testWidgets('Medicine form validates required medicine name',
      (tester) async {
    await tester.pumpWidget(_wrap(const MedicineFormScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('medicineSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter the medicine name.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Medicine form pops a Medicine on submit', (tester) async {
    Medicine? result;
    await tester.pumpWidget(_wrap(_Harness(onMedicine: (m) => result = m)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('medicineNameField')), 'Paracetamol');
    await tester.enterText(find.byKey(const Key('dosageField')), '500 mg');
    await tester.tap(find.byKey(const Key('medicineSubmitButton')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.medicineName, 'Paracetamol');
    expect(result!.dosage, '500 mg');
    expect(result!.id, isNotEmpty);
  });

  testWidgets('Medicine form pre-fills and edits an existing medicine',
      (tester) async {
    const medicine = Medicine(
      id: 'm1',
      medicineName: 'Aspirin',
      dosage: '75 mg',
      frequency: 'Once daily',
      duration: '30 days',
      instructions: 'Morning',
    );
    Medicine? result;
    await tester.pumpWidget(_wrap(_Harness(
      medicine: medicine,
      onMedicine: (m) => result = m,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const Key('medicineNameField'));
    expect(nameField, findsOneWidget);
    expect(tester.widget<TextFormField>(nameField).controller?.text, 'Aspirin');
    await tester.enterText(nameField, 'Aspirin Low Dose');
    await tester.tap(find.byKey(const Key('medicineSubmitButton')));
    await tester.pumpAndSettle();

    expect(result!.id, 'm1');
    expect(result!.medicineName, 'Aspirin Low Dose');
    expect(result!.frequency, 'Once daily');
  });

  testWidgets('Choosing Other frequency reveals a free text field',
      (tester) async {
    await tester.pumpWidget(_wrap(const MedicineFormScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('frequencyDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    // Free-text frequency field appears.
    expect(find.byKey(const Key('otherFrequencyField')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Medicine form does not overflow on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const MedicineFormScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

/// Test harness that captures the medicine returned via Navigator.pop.
class _Harness extends StatefulWidget {
  final Medicine? medicine;
  final ValueChanged<Medicine> onMedicine;

  const _Harness({this.medicine, required this.onMedicine});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  Future<void> _open() async {
    final result = await Navigator.of(context).pushNamed(
      '/medicine-form-test',
      arguments: MedicineFormArguments(medicine: widget.medicine),
    );
    if (result != null && mounted) widget.onMedicine(result as Medicine);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: TextButton(onPressed: _open, child: const Text('open')),
    );
  }
}
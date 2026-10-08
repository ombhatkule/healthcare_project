import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/config/app_router.dart';
import 'package:healthcare_app/features/doctor_recommendation/services/doctor_recommendation_service.dart';
import 'package:healthcare_app/features/doctor_recommendation/services/mock_doctor_repository.dart';
import 'package:healthcare_app/features/doctor_recommendation/presentation/widgets/doctor_card.dart';
import 'package:healthcare_app/features/doctor_search/presentation/doctor_search_screen.dart';
import 'package:healthcare_app/features/doctor_search/presentation/providers/doctor_search_controller.dart';
import 'package:healthcare_app/features/doctor_recommendation/presentation/doctor_details_screen.dart';
import 'package:provider/provider.dart';

/// Phase 10: DoctorSearchScreen widget tests against the real mock repo.
void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    final service = MockDoctorRepository();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DoctorRecommendationService>.value(value: service),
          ChangeNotifierProvider<DoctorSearchController>(
            create: (_) => DoctorSearchController(service),
          ),
        ],
        child: MaterialApp(
          onGenerateRoute: AppRouter.generateRoute,
          home: const DoctorSearchScreen(),
        ),
      ),
    );
    // Options load (2x150ms) + initial search (150ms), then render results.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  /// Fires the debounce timer then the mock search delay, and settles.
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  Future<void> setSpecialty(WidgetTester tester, String specialty) async {
    await tester.tap(find.text('All Specialties'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(specialty).last);
    await tester.pumpAndSettle();
  }

  testWidgets('renders search bar and derived filters', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Specialty'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);
    expect(find.text('Sort By'), findsOneWidget);
    expect(find.text('All Specialties'), findsOneWidget);
    expect(find.text('All Locations'), findsOneWidget);
    expect(find.text('Any Rating'), findsOneWidget);
    expect(find.text('Recommended Doctors'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows results and result count by default', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('doctors found'), findsOneWidget);
    expect(find.byType(DoctorCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing a query filters results after debounce', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'Dr. Aarti');
    await settleSearch(tester);

    expect(find.text('Dr. Aarti Sharma'), findsOneWidget);
    expect(find.textContaining('doctors found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no match shows empty state', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'zzz-nonexistent');
    await settleSearch(tester);

    expect(find.text('No doctors available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('specialty filter narrows results', (tester) async {
    await pumpScreen(tester);

    await setSpecialty(tester, 'Cardiologist');

    expect(
      find.textContaining('3 doctors found'),
      findsOneWidget,
    );
    expect(find.byType(DoctorCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clear filters restores the full result set', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'zzz-nonexistent');
    await settleSearch(tester);
    expect(find.text('No doctors available'), findsOneWidget);

    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();

    expect(find.textContaining('doctors found'), findsOneWidget);
    expect(find.byType(DoctorCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a result opens the shared Doctor Details screen',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'Dr. Aarti');
    await settleSearch(tester);

    await tester.tap(find.text('Dr. Aarti Sharma'));
    await tester.pumpAndSettle();

    expect(
      find.byType(DoctorDetailsScreen),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow at a narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpScreen(tester);

    expect(find.text('Specialty'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

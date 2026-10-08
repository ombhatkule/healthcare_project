import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/disease_specialty_mapping.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/doctor.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/navigation_args.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/specialty_summary.dart';
import 'package:healthcare_app/features/doctor_recommendation/presentation/doctor_details_screen.dart';
import 'package:healthcare_app/features/doctor_recommendation/presentation/doctor_recommendation_screen.dart';
import 'package:healthcare_app/features/doctor_recommendation/presentation/providers/doctor_recommendation_controller.dart';
import 'package:healthcare_app/features/doctor_recommendation/presentation/widgets/doctor_card.dart';
import 'package:healthcare_app/features/doctor_recommendation/services/doctor_recommendation_service.dart';
import 'package:healthcare_app/features/doctor_search/presentation/doctor_search_screen.dart';
import 'package:healthcare_app/features/doctor_search/presentation/providers/doctor_search_controller.dart';
import 'package:provider/provider.dart';

/// A controllable fake service used to test loading/error/empty states.
class _FakeDoctorService implements DoctorRecommendationService {
  _FakeDoctorService({
    List<Doctor> doctors = const [],
    this.failDoctors = false,
  }) : _doctors = doctors;

  final List<Doctor> _doctors;
  final bool failDoctors;

  @override
  Future<List<Doctor>> getDoctorsBySpecialty(String specialty) async {
    if (failDoctors) throw Exception('network');
    return List.unmodifiable(
      _doctors.where((d) => d.specialty == specialty),
    );
  }

  @override
  Future<Doctor?> getDoctorById(String id) async {
    if (failDoctors) throw Exception('network');
    for (final doctor in _doctors) {
      if (doctor.id == id) return doctor;
    }
    return null;
  }

  @override
  Future<List<SpecialtySummary>> getSpecialtySummaries() async {
    return [
      const SpecialtySummary(specialty: Specialties.generalPhysician, doctorCount: 1),
      const SpecialtySummary(specialty: Specialties.cardiologist, doctorCount: 2),
    ];
  }

  @override
  Future<List<String>> getLocations() async => const ['Pune'];

  @override
  Future<List<Doctor>> searchDoctors({
    String query = '',
    String specialty = '',
    String location = '',
    double minRating = 0,
    DoctorSort sort = DoctorSort.recommended,
  }) async {
    if (failDoctors) throw Exception('network');
    final results = _doctors
        .where((d) => DoctorSearchHelper.matchesQuery(d, query))
        .where((d) => DoctorSearchHelper.matchesSpecialty(d, specialty))
        .where((d) => DoctorSearchHelper.matchesLocation(d, location))
        .where((d) => DoctorSearchHelper.matchesMinRating(d, minRating))
        .toList();
    DoctorSearchHelper.sortDoctors(results, sort);
    return List.unmodifiable(results);
  }
}

const _sampleDoctor = Doctor(
  id: 'doc-test-01',
  name: 'Dr. Test Doctor',
  specialty: 'Cardiologist',
  qualification: 'MBBS, MD, DM (Cardiology)',
  experienceYears: 10,
  hospital: 'Test Hospital',
  location: 'Test City',
  consultationFee: 1000,
  rating: 4.5,
  reviewCount: 50,
  availableToday: true,
  languages: ['English', 'Hindi'],
);

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      Provider<DoctorRecommendationService>.value(value: _FakeDoctorService()),
      ChangeNotifierProvider<DoctorRecommendationController>(
        create: (_) => DoctorRecommendationController(_FakeDoctorService()),
      ),
      ChangeNotifierProvider<DoctorSearchController>(
        create: (_) => DoctorSearchController(_FakeDoctorService()),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('DoctorRecommendationScreen', () {
    testWidgets('shows doctors for a predicted disease', (tester) async {
      final service = _FakeDoctorService(doctors: [_sampleDoctor]);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DoctorRecommendationService>.value(value: service),
            ChangeNotifierProvider<DoctorRecommendationController>(
              create: (_) => DoctorRecommendationController(service),
            ),
          ],
          child: MaterialApp(
            home: const DoctorRecommendationScreen(
              args: DoctorRecommendationArgs(
                predictedDisease: 'Heart Attack',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heart Attack'), findsOneWidget);
      expect(find.text('Cardiologist'), findsWidgets);
      expect(find.text('Dr. Test Doctor'), findsOneWidget);
      // No overflow.
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows empty state when no doctors match', (tester) async {
      final service = _FakeDoctorService();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DoctorRecommendationService>.value(value: service),
            ChangeNotifierProvider<DoctorRecommendationController>(
              create: (_) => DoctorRecommendationController(service),
            ),
          ],
          child: MaterialApp(
            home: const DoctorRecommendationScreen(
              args: DoctorRecommendationArgs(specialty: 'Cardiologist'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No doctors available'), findsOneWidget);
    });

    testWidgets('shows error state with retry on failure', (tester) async {
      final service =
          _FakeDoctorService(doctors: [_sampleDoctor], failDoctors: true);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DoctorRecommendationService>.value(value: service),
            ChangeNotifierProvider<DoctorRecommendationController>(
              create: (_) => DoctorRecommendationController(service),
            ),
          ],
          child: const MaterialApp(
            home: DoctorRecommendationScreen(
              args: DoctorRecommendationArgs(specialty: 'Cardiologist'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Dr. Test Doctor'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('DoctorSearchScreen', () {
    Widget searchApp(_FakeDoctorService service) {
      return MultiProvider(
        providers: [
          Provider<DoctorRecommendationService>.value(value: service),
          ChangeNotifierProvider<DoctorRecommendationController>(
            create: (_) => DoctorRecommendationController(service),
          ),
          ChangeNotifierProvider<DoctorSearchController>(
            create: (_) => DoctorSearchController(service),
          ),
        ],
        child: const MaterialApp(home: DoctorSearchScreen()),
      );
    }

    testWidgets('shows all doctors by default', (tester) async {
      final service = _FakeDoctorService(doctors: [_sampleDoctor]);
      await tester.pumpWidget(searchApp(service));
      await tester.pumpAndSettle();

      expect(find.text('Search'), findsWidgets);
      expect(find.text('Dr. Test Doctor'), findsOneWidget);
      expect(find.text('1 doctors found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('filters results by query text', (tester) async {
      final service = _FakeDoctorService(doctors: [_sampleDoctor]);
      await tester.pumpWidget(searchApp(service));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'nonexistent doctor',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('No doctors available'), findsOneWidget);
      expect(find.text('Dr. Test Doctor'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search doesnt match -> empty state, then clear filters',
        (tester) async {
      final service = _FakeDoctorService(doctors: [_sampleDoctor]);
      await tester.pumpWidget(searchApp(service));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz query');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('No doctors available'), findsOneWidget);

      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Dr. Test Doctor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows error state with retry on failure', (tester) async {
      final service =
          _FakeDoctorService(doctors: [_sampleDoctor], failDoctors: true);
      await tester.pumpWidget(searchApp(service));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('DoctorDetailsScreen', () {
    testWidgets('renders doctor information', (tester) async {
      await tester.pumpWidget(
        _wrap(const DoctorDetailsScreen(
          args: DoctorDetailsArgs(doctor: _sampleDoctor),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Test Doctor'), findsOneWidget);
      expect(find.text('Cardiologist'), findsWidgets);
      expect(find.text('MBBS, MD, DM (Cardiology)'), findsOneWidget);
      expect(find.text('₹1000'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Book Appointment'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Book Appointment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a fallback when no doctor is provided', (tester) async {
      await tester.pumpWidget(_wrap(const DoctorDetailsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Doctor not found'), findsOneWidget);
    });
  });

  group('DoctorCard', () {
    testWidgets('renders without overflow at a narrow width', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            child: DoctorCard(
              doctor: _sampleDoctor,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Test Doctor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
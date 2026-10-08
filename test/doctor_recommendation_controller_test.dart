import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/disease_specialty_mapping.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/doctor.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/specialty_summary.dart';
import 'package:healthcare_app/features/doctor_recommendation/presentation/providers/doctor_recommendation_controller.dart';
import 'package:healthcare_app/features/doctor_recommendation/services/doctor_recommendation_service.dart';

class _FakeService implements DoctorRecommendationService {
  final Map<String, List<Doctor>> bySpecialty;
  bool failDoctors;
  bool failSummaries;

  _FakeService({
    this.bySpecialty = const {},
    this.failDoctors = false,
    this.failSummaries = false,
  });

  @override
  Future<List<Doctor>> getDoctorsBySpecialty(String specialty) async {
    if (failDoctors) throw Exception('boom');
    return List.unmodifiable(bySpecialty[specialty] ?? const []);
  }

  @override
  Future<Doctor?> getDoctorById(String id) async => null;

  @override
  Future<List<SpecialtySummary>> getSpecialtySummaries() async {
    if (failSummaries) throw Exception('boom');
    return const [
      SpecialtySummary(specialty: Specialties.generalPhysician, doctorCount: 1),
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
    if (failDoctors) throw Exception('boom');
    final results = bySpecialty.values
        .expand((d) => d)
        .where((d) => DoctorSearchHelper.matchesQuery(d, query))
        .where((d) => DoctorSearchHelper.matchesSpecialty(d, specialty))
        .where((d) => DoctorSearchHelper.matchesLocation(d, location))
        .where((d) => DoctorSearchHelper.matchesMinRating(d, minRating))
        .toList();
    DoctorSearchHelper.sortDoctors(results, sort);
    return List.unmodifiable(results);
  }
}

const _doctor = Doctor(
  id: 'x',
  name: 'Dr. X',
  specialty: 'Cardiologist',
  qualification: 'MBBS',
  experienceYears: 5,
  hospital: 'H',
  location: 'L',
  consultationFee: 500,
  rating: 4.0,
  reviewCount: 10,
  availableToday: true,
);

void main() {
  test('loadForDisease resolves specialty via mapping and loads doctors',
      () async {
    final service = _FakeService(bySpecialty: {
      'Cardiologist': [_doctor],
    });
    final controller = DoctorRecommendationController(service);

    await controller.loadForDisease('Heart Attack');

    expect(controller.predictedDisease, 'Heart Attack');
    expect(controller.recommendedSpecialty, Specialties.cardiologist);
    expect(controller.isFromPrediction, isTrue);
    expect(controller.doctors, hasLength(1));
    expect(controller.isLoading, isFalse);
    expect(controller.hasError, isFalse);
  });

  test('loadForDisease falls back to General Physician for unmapped disease',
      () async {
    final service = _FakeService(bySpecialty: {
      'General Physician': [_doctor],
    });
    final controller = DoctorRecommendationController(service);

    await controller.loadForDisease('SomeUnknownDisease');

    expect(controller.recommendedSpecialty, Specialties.generalPhysician);
    expect(controller.doctors, hasLength(1));
  });

  test('loadForSpecialty clears prediction context', () async {
    final service = _FakeService(bySpecialty: {
      'Cardiologist': [_doctor],
    });
    final controller = DoctorRecommendationController(service);

    await controller.loadForDisease('Heart Attack');
    await controller.loadForSpecialty('Cardiologist');

    expect(controller.predictedDisease, isNull);
    expect(controller.isFromPrediction, isFalse);
    expect(controller.activeSpecialty, 'Cardiologist');
    expect(controller.doctors, hasLength(1));
  });

  test('failure sets error, retry reloads successfully', () async {
    final service = _FakeService(
      bySpecialty: {
        'Cardiologist': [_doctor],
      },
      failDoctors: true,
    );
    final controller = DoctorRecommendationController(service);

    await controller.loadForSpecialty('Cardiologist');
    expect(controller.hasError, isTrue);

    // "Network" recovers.
    service.failDoctors = false;
    await controller.retry();
    expect(controller.hasError, isFalse);
    expect(controller.doctors, hasLength(1));
  });

  test('loadSpecialtySummaries surfaces failure for browse screen', () async {
    final service = _FakeService(failSummaries: true);
    final controller = DoctorRecommendationController(service);

    await controller.loadSpecialtySummaries();

    expect(controller.hasError, isTrue);
    expect(controller.specialties, isEmpty);
    expect(controller.isLoading, isFalse);
  });
}
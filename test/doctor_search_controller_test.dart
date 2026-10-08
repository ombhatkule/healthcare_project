import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/doctor.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/specialty_summary.dart';
import 'package:healthcare_app/features/doctor_recommendation/services/doctor_recommendation_service.dart';
import 'package:healthcare_app/features/doctor_search/presentation/providers/doctor_search_controller.dart';

/// Phase 10: DoctorSearchController unit tests (no widgets).
void main() {
  test('initialize loads options and performs the initial search', () async {
    final controller = DoctorSearchController(_FakeSearchService(doctors: [
      _alice,
      _bob,
    ]));

    await controller.initialize();

    expect(controller.isLoading, isFalse);
    expect(controller.hasError, isFalse);
    expect(controller.results, hasLength(2));
    expect(controller.specialties, isNotEmpty);
    expect(controller.locations, contains('Pune'));
    expect(controller.hasActiveFilters, isFalse);
  });

  test('updateQuery debounces: single search after rapid typing', () async {
    final service = _FakeSearchService(doctors: [_alice, _bob]);
    final controller = DoctorSearchController(service);

    await controller.initialize();
    controller.updateQuery('a');
    controller.updateQuery('al');
    controller.updateQuery('ali');

    expect(service.searchCalls, 1);
    // Let the final debounced timer fire.
    await _settleDebounce(controller);
    expect(service.searchCalls, 2);
    expect(controller.results, hasLength(1));
    expect(controller.results.first.name, _alice.name);
  });

  test('filters combine with AND and update results immediately', () async {
    final controller = DoctorSearchController(_FakeSearchService(doctors: [
      _alice, // Cardiologist, Pune, 4.6
      _bob, // Cardiologist, Mumbai, 4.2
      _carol, // General Physician, Pune, 4.4
    ]));
    await controller.initialize();

    controller.setSpecialty('Cardiologist');
    await untilIdle(controller);
    expect(controller.results, hasLength(2));

    controller.setLocation('Pune');
    await untilIdle(controller);
    expect(controller.results, hasLength(1));
    expect(controller.results.first.netId, _alice.netId);

    controller.setMinRating(4.5);
    await untilIdle(controller);
    expect(controller.results, hasLength(1));

    // Lower rating removes constraints: still the Pune cardiologist + GP.
    controller.setMinRating(4.3);
    controller.setSpecialty('');
    await untilIdle(controller);
    expect(controller.results, hasLength(2));
  });

  test('hasActiveFilters reflects active filters', () async {
    final controller = DoctorSearchController(_FakeSearchService(doctors: [
      _alice,
    ]));
    await controller.initialize();

    expect(controller.hasActiveFilters, isFalse);

    controller.updateQuery('x');
    expect(controller.hasActiveFilters, isTrue);

    controller.clearFilters();
    expect(controller.hasActiveFilters, isFalse);
  });

  test('clearFilters resets query and all filters, then reloads', () async {
    final controller = DoctorSearchController(_FakeSearchService(doctors: [
      _alice,
      _bob,
    ]));
    await controller.initialize();

    controller.setSpecialty('Cardiologist');
    controller.setLocation('Mumbai');
    controller.setMinRating(4.2);
    controller.setSort(DoctorSort.mostExperienced);
    controller.updateQuery('bob');
    await untilIdle(controller);
    expect(controller.hasActiveFilters, isTrue);

    await controller.clearFilters();
    expect(controller.query, isEmpty);
    expect(controller.selectedSpecialty, isEmpty);
    expect(controller.selectedLocation, isEmpty);
    expect(controller.minRating, 0);
    expect(controller.sort, DoctorSort.recommended);
    expect(controller.hasActiveFilters, isFalse);
    expect(controller.results, hasLength(2));
  });

  test('failure sets error and retry reloads successfully', () async {
    final service = _FakeSearchService(doctors: [_alice], failSearch: true);
    final controller = DoctorSearchController(service);

    await controller.initialize();
    expect(controller.hasError, isTrue);
    expect(controller.results, isEmpty);

    service.failSearch = false;
    await controller.retry();
    expect(controller.hasError, isFalse);
    expect(controller.results, hasLength(1));
  });

  test('sort is passed through to the service', () async {
    final service = _FakeSearchService(doctors: [_alice, _bob]);
    final controller = DoctorSearchController(service);

    await controller.initialize();
    controller.setSort(DoctorSort.highestRated);
    await untilIdle(controller);

    expect(service.lastSort, DoctorSort.highestRated);
  });
}

/// Extends [Doctor] with no behavior; just a typed alias for readability.
extension on Doctor {
  String get netId => id;
}

Future<void> untilIdle(DoctorSearchController controller) async {
  // The fake service completes synchronously; a couple of pumps flush
  // the notifyListeners chain.
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  expect(controller.isLoading, isFalse);
}

Future<void> _settleDebounce(DoctorSearchController controller) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
  await Future<void>.delayed(Duration.zero);
  expect(controller.isLoading, isFalse);
}

const _alice = Doctor(
  id: 'a',
  name: 'Dr. Alice',
  specialty: 'Cardiologist',
  qualification: 'MBBS',
  experienceYears: 5,
  hospital: 'H-A',
  location: 'Koregaon Park, Pune',
  consultationFee: 500,
  rating: 4.6,
  reviewCount: 10,
  availableToday: true,
);

const _bob = Doctor(
  id: 'b',
  name: 'Dr. Bob',
  specialty: 'Cardiologist',
  qualification: 'MBBS',
  experienceYears: 10,
  hospital: 'H-B',
  location: 'Mulund, Mumbai',
  consultationFee: 700,
  rating: 4.2,
  reviewCount: 5,
  availableToday: false,
);

const _carol = Doctor(
  id: 'c',
  name: 'Dr. Carol',
  specialty: 'General Physician',
  qualification: 'MBBS',
  experienceYears: 8,
  hospital: 'H-C',
  location: 'Baner, Pune',
  consultationFee: 450,
  rating: 4.4,
  reviewCount: 8,
  availableToday: false,
);

class _FakeSearchService implements DoctorRecommendationService {
  _FakeSearchService({required this.doctors, this.failSearch = false});

  final List<Doctor> doctors;
  bool failSearch;
  int searchCalls = 0;
  DoctorSort lastSort = DoctorSort.recommended;

  @override
  Future<List<Doctor>> searchDoctors({
    String query = '',
    String specialty = '',
    String location = '',
    double minRating = 0,
    DoctorSort sort = DoctorSort.recommended,
  }) async {
    searchCalls++;
    lastSort = sort;
    if (failSearch) throw Exception('network');
    return List.unmodifiable(
      doctors
          .where((d) => DoctorSearchHelper.matchesQuery(d, query))
          .where((d) => DoctorSearchHelper.matchesSpecialty(d, specialty))
          .where((d) => DoctorSearchHelper.matchesLocation(d, location))
          .where((d) => DoctorSearchHelper.matchesMinRating(d, minRating))
          .toList(),
    );
  }

  @override
  Future<List<Doctor>> getDoctorsBySpecialty(String specialty) async => [];

  @override
  Future<List<String>> getLocations() async => const ['Pune', 'Mumbai'];

  @override
  Future<Doctor?> getDoctorById(String id) async => null;

  @override
  Future<List<SpecialtySummary>> getSpecialtySummaries() async => const [
        SpecialtySummary(specialty: 'Cardiologist', doctorCount: 2),
        SpecialtySummary(specialty: 'General Physician', doctorCount: 1),
      ];
}
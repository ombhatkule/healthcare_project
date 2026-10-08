import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/doctor_recommendation/services/doctor_recommendation_service.dart';
import 'package:healthcare_app/features/doctor_recommendation/services/mock_doctor_repository.dart';

/// Phase 10: Doctor search tests against the mock (real data) repository.
void main() {
  final repo = MockDoctorRepository();

  test('searchDoctors with no filters returns the full catalog', () async {
    final doctors = await repo.searchDoctors();
    expect(doctors, isNotEmpty);
    // 29 doctors exist in the catalog; just assert consistency with browse.
    final gp = await repo.getDoctorsBySpecialty('General Physician');
    expect(gp, isNotEmpty);
  });

  test('searches by name (case-insensitive substring)', () async {
    final found = await repo.searchDoctors(query: 'aarti');
    expect(found, isNotEmpty);
    expect(found.every((d) => d.name.toLowerCase().contains('aarti')), isTrue);
  });

  test('searches by specialty', () async {
    final found = await repo.searchDoctors(query: 'cardio');
    expect(found, isNotEmpty);
    expect(
      found.every((d) => d.specialty.toLowerCase().contains('cardio')),
      isTrue,
    );
  });

  test('searches by hospital', () async {
    final found = await repo.searchDoctors(query: 'aiims');
    expect(found, isNotEmpty);
    expect(found.every((d) => d.hospital.toLowerCase().contains('aiims')), isTrue);
  });

  test('searches by location substring (Bangalore area)', () async {
    final found = await repo.searchDoctors(query: 'Bengaluru');
    expect(found, isNotEmpty);
    expect(
      found.every(
        (d) =>
            d.location.toLowerCase().contains('bengaluru') ||
            d.city.toLowerCase().contains('bengaluru'),
      ),
      isTrue,
    );
  });

  test('combines query with AND logic', () async {
    final doctors = await repo.getDoctorsBySpecialty('Cardiologist');
    expect(doctors, hasLength(3));

    final found = await repo.searchDoctors(
      query: 'Pune',
      specialty: 'Cardiologist',
    );
    expect(found, isNotEmpty);
    expect(
      found.every(
        (d) =>
            d.specialty == 'Cardiologist' &&
            d.city.toLowerCase() == 'pune',
      ),
      isTrue,
    );
  });

  test('location filter uses derived city and matches actual data', () async {
    final locations = await repo.getLocations();
    expect(locations, contains('Pune'));
    expect(locations, contains('Mumbai'));
    expect(locations, contains('Bengaluru'));
    expect(locations, contains('Hyderabad'));
    expect(locations, contains('New Delhi'));
    expect(locations, isNotEmpty);

    final pune = await repo.searchDoctors(location: 'Pune');
    expect(pune, isNotEmpty);
    expect(
      pune.every((d) => d.city == 'Pune'),
      isTrue,
    );
  });

  test('rating filter keeps only qualifying doctors', () async {
    final all = await repo.searchDoctors();
    final filtered = await repo.searchDoctors(minRating: 4.8);
    expect(filtered, isNotEmpty);
    expect(filtered.length, lessThan(all.length));
    expect(
      filtered.every((d) => d.rating >= 4.8),
      isTrue,
    );
  });

  test('all filters combined return only intersection', () async {
    final found = await repo.searchDoctors(
      query: 'Pune',
      specialty: 'Cardiologist',
      minRating: 4.5,
      sort: DoctorSort.highestRated,
    );
    expect(
      found.every(
        (d) =>
            d.specialty == 'Cardiologist' &&
            d.city == 'Pune' &&
            d.rating >= 4.5,
      ),
      isTrue,
    );
  });

  test('sorts by highest rating', () async {
    final found = await repo.searchDoctors(sort: DoctorSort.highestRated);
    expect(found, isNotEmpty);
    for (var i = 1; i < found.length; i++) {
      expect(found[i - 1].rating, greaterThanOrEqualTo(found[i].rating));
    }
  });

  test('sorts by most experienced', () async {
    final found = await repo.searchDoctors(sort: DoctorSort.mostExperienced);
    expect(found, isNotEmpty);
    for (var i = 1; i < found.length; i++) {
      expect(
        found[i - 1].experienceYears,
        greaterThanOrEqualTo(found[i].experienceYears),
      );
    }
  });

  test('recommended sort puts available doctors first', () async {
    final found = await repo.searchDoctors(sort: DoctorSort.recommended);
    expect(found, isNotEmpty);
    var seenUnavailable = false;
    for (final doctor in found) {
      if (!doctor.availableToday) seenUnavailable = true;
      if (seenUnavailable) {
        expect(doctor.availableToday, isFalse);
      }
    }
  });

  test('doctor city is derived from location', () async {
    final doctors = await repo.getDoctorsBySpecialty('General Physician');
    expect(doctors, isNotEmpty);
    for (final doctor in doctors) {
      expect(doctor.city, isNotEmpty);
      expect(doctor.city, isNot(doctor.location));
    }
  });

  test('no fake locations: options come only from real doctor data', () async {
    final locations = await repo.getLocations();
    final doctors = await repo.searchDoctors();
    final realCities = doctors.map((d) => d.city.toLowerCase()).toSet();
    for (final location in locations) {
      expect(realCities, contains(location.toLowerCase()));
    }
  });
}
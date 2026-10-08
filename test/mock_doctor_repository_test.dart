import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/disease_specialty_mapping.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/doctor.dart';
import 'package:healthcare_app/features/doctor_recommendation/services/mock_doctor_repository.dart';

/// Phase 9: MockDoctorRepository tests.
void main() {
  final repo = MockDoctorRepository();

  test('returns doctors for a known specialty', () async {
    final doctors = await repo.getDoctorsBySpecialty(Specialties.cardiologist);
    expect(doctors, isNotEmpty);
    expect(
      doctors.every((d) => d.specialty == Specialties.cardiologist),
      isTrue,
    );
  });

  test('specialty matching is case-insensitive', () async {
    final doctors = await repo.getDoctorsBySpecialty('cardioLOGIst');
    expect(doctors, isNotEmpty);
  });

  test('returns empty list for unknown specialty', () async {
    final doctors = await repo.getDoctorsBySpecialty('Ophthalmologist');
    expect(doctors, isEmpty);
  });

  test('every supported specialty is in the summaries list', () async {
    final summaries = await repo.getSpecialtySummaries();
    final names = summaries.map((s) => s.specialty).toSet();
    for (final specialty in Specialties.all) {
      expect(names, contains(specialty));
    }
  });

  test('summaries report non-negative doctor counts', () async {
    final summaries = await repo.getSpecialtySummaries();
    for (final summary in summaries) {
      expect(summary.doctorCount, greaterThanOrEqualTo(0));
      expect(summary.countLabel, isNotEmpty);
    }
  });

  test('General Physician has at least one doctor (fallback safety)',
      () async {
    final doctors =
        await repo.getDoctorsBySpecialty(Specialties.generalPhysician);
    expect(doctors, isNotEmpty);
  });

  test('doctor ids are unique', () async {
    final summaries = await repo.getSpecialtySummaries();
    final doctors = <Doctor>[];
    for (final summary in summaries) {
      if (summary.doctorCount > 0) {
        doctors.addAll(
          await repo.getDoctorsBySpecialty(summary.specialty),
        );
      }
    }
    final ids = doctors.map((d) => d.id).toSet();
    expect(ids.length, doctors.length);
  });

  test('doctor records are realistic and complete', () async {
    final doctor = (await repo.getDoctorsBySpecialty('General Physician')).first;
    expect(doctor.name, contains('Dr.'));
    expect(doctor.qualification, isNotEmpty);
    expect(doctor.hospital, isNotEmpty);
    expect(doctor.location, isNotEmpty);
    expect(doctor.experienceYears, greaterThan(0));
    expect(doctor.consultationFee, greaterThan(0));
    expect(doctor.rating, inInclusiveRange(1, 5));
    expect(doctor.reviewCount, greaterThanOrEqualTo(0));
    expect(doctor.languages, isNotEmpty);
    expect(doctor.initials, isNotEmpty);
  });

  test('getDoctorById returns the right doctor or null', () async {
    final doctor = (await repo.getDoctorsBySpecialty('Cardiologist')).first;
    final found = await repo.getDoctorById(doctor.id);
    expect(found, isNotNull);
    expect(found!.id, doctor.id);

    final missing = await repo.getDoctorById('no-such-id');
    expect(missing, isNull);
  });
}
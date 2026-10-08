import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/medical_records/models/medical_record.dart';
import 'package:healthcare_app/features/medical_records/models/medical_record_category.dart';
import 'package:healthcare_app/features/medical_records/models/medical_profile.dart';
import 'package:healthcare_app/features/medical_records/models/past_surgery.dart';

void main() {
  group('MedicalRecord', () {
    final date = DateTime(2026, 9, 11);

    MedicalRecord sut({String? id}) {
      return MedicalRecord(
        id: id ?? 'rec-1',
        userId: 'user-1',
        title: 'Annual Check-up',
        category: MedicalRecordCategory.doctorVisit,
        description: 'Routine check-up',
        date: date,
        doctorName: 'Dr. Smith',
        hospitalName: 'General Hospital',
        notes: 'Follow-up recommended',
        createdAt: DateTime(2026, 9, 10),
      );
    }

    test('toMap/fromMap round-trips all fields', () {
      final record = sut();
      final map = record.toMap();
      final restored = MedicalRecord.fromMap(record.id, map);

      expect(restored.id, record.id);
      expect(restored.userId, record.userId);
      expect(restored.title, record.title);
      expect(restored.category, record.category);
      expect(restored.description, record.description);
      expect(restored.date, date);
      expect(restored.doctorName, record.doctorName);
      expect(restored.hospitalName, record.hospitalName);
      expect(restored.notes, record.notes);
    });

    test('toMap with includeTimestamps sets createdAt and updatedAt', () {
      final map = sut().toMap(includeTimestamps: true);
      expect(map['createdAt'], isNotNull);
      expect(map['updatedAt'], isNotNull);
    });

    test('category parses unknown value as general', () {
      expect(
        MedicalRecordCategory.parse('unknown'),
        MedicalRecordCategory.general,
      );
    });

    test('category.label returns human-readable names', () {
      expect(MedicalRecordCategory.general.label, 'General');
      expect(MedicalRecordCategory.surgery.label, 'Surgery');
      expect(MedicalRecordCategory.doctorVisit.label, 'Doctor Visit');
    });

    test('copyWith preserves other fields', () {
      final original = sut();
      final updated = original.copyWith(title: 'New Title');
      expect(updated.title, 'New Title');
      expect(updated.doctorName, original.doctorName);
      expect(updated.userId, original.userId);
    });
  });

  group('MedicalProfile', () {
    test('fromMap/toMap round-trips all fields', () {
      final profile = MedicalProfile(
        userId: 'u1',
        bloodGroup: 'O+',
        allergies: ['Penicillin'],
        conditions: ['Asthma'],
        familyHistory: 'Heart disease',
        pastSurgeries: const [
          PastSurgery(name: 'Appendectomy', year: 2022, hospital: 'City Hospital'),
        ],
      );

      final map = profile.toMap(includeTimestamps: true);
      final restored = MedicalProfile.fromMap('u1', map);

      expect(restored.userId, 'u1');
      expect(restored.bloodGroup, 'O+');
      expect(restored.allergies, ['Penicillin']);
      expect(restored.conditions, ['Asthma']);
      expect(restored.familyHistory, 'Heart disease');
      expect(restored.pastSurgeries.length, 1);
      expect(restored.pastSurgeries.first.name, 'Appendectomy');
    });

    test('isEmpty is true when all fields are empty', () {
      const empty = MedicalProfile(userId: 'u1');
      expect(empty.isEmpty, isTrue);
    });

    test('isEmpty is false when allergies present', () {
      const p = MedicalProfile(userId: 'u1', allergies: ['Peanuts']);
      expect(p.isEmpty, isFalse);
    });
  });

  group('PastSurgery', () {
    test('toMap/fromMap round-trips', () {
      const s = PastSurgery(
        name: 'Appendectomy',
        year: 2022,
        hospital: 'City Hospital',
        notes: 'No complications',
      );
      final map = s.toMap();
      final restored = PastSurgery.fromMap(map);

      expect(restored.name, s.name);
      expect(restored.year, s.year);
      expect(restored.hospital, s.hospital);
      expect(restored.notes, s.notes);
    });

    test('copyWith preserves other fields', () {
      const s = PastSurgery(name: 'Appendectomy', year: 2022);
      final updated = s.copyWith(notes: 'Completed');
      expect(updated.name, s.name);
      expect(updated.year, s.year);
      expect(updated.notes, 'Completed');
    });
  });
}
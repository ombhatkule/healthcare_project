import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/medical_records/models/medical_profile.dart';
import 'package:healthcare_app/features/medical_records/models/medical_record.dart';
import 'package:healthcare_app/features/medical_records/models/medical_record_category.dart';
import 'package:healthcare_app/features/medical_records/presentation/providers/medical_records_controller.dart';
import 'package:healthcare_app/features/medical_records/services/medical_record_service.dart';
import 'fake_medical_record_service.dart';

void main() {
  MedicalRecord makeRecord({
    String? id,
    String userId = 'user-1',
    String title = 'Check-up',
    MedicalRecordCategory category = MedicalRecordCategory.doctorVisit,
    DateTime? date,
  }) {
    return MedicalRecord(
      id: id ?? 'rec-1',
      userId: userId,
      title: title,
      category: category,
      date: date ?? DateTime(2026, 9, 11),
    );
  }

  group('MedicalRecordsController', () {
    test('loadAll populates records and profile', () async {
      final service = FakeMedicalRecordService(
        initialRecords: [
          makeRecord(id: 'r1', title: 'Visit 1'),
          makeRecord(id: 'r2', title: 'Visit 2', category: MedicalRecordCategory.medicalHistory),
        ],
        profile: const MedicalProfile(
          userId: 'user-1',
          bloodGroup: 'A+',
        ),
      );
      final controller = MedicalRecordsController(service);
      await controller.loadAll('user-1');

      expect(controller.records.length, 2);
      expect(controller.medicalProfile?.bloodGroup, 'A+');
      expect(controller.historyCount, 1);
      expect(controller.visitCount, 1);
      expect(controller.isLoading, isFalse);
    });

    test('createRecord adds to the list', () async {
      final service = FakeMedicalRecordService();
      final controller = MedicalRecordsController(service);
      await controller.loadAll('user-1');

      final ok = await controller.createRecord(makeRecord());
      expect(ok, isTrue);
      expect(controller.records.length, 1);
      expect(controller.records.first.id, isNotEmpty);
    });

    test('updateRecord replaces in the list without creating duplicate', () async {
      final existing = makeRecord(id: 'r1', title: 'Old Title');
      final service = FakeMedicalRecordService(initialRecords: [existing]);
      final controller = MedicalRecordsController(service);
      await controller.loadAll('user-1');

      final updated = existing.copyWith(title: 'New Title');
      final ok = await controller.updateRecord(updated);
      expect(ok, isTrue);
      expect(controller.records.length, 1);
      expect(controller.records.first.title, 'New Title');
    });

    test('deleteRecord removes from the list', () async {
      final existing = makeRecord(id: 'r1');
      final service = FakeMedicalRecordService(initialRecords: [existing]);
      final controller = MedicalRecordsController(service);
      await controller.loadAll('user-1');

      final ok = await controller.deleteRecord('user-1', 'r1');
      expect(ok, isTrue);
      expect(controller.records, isEmpty);
    });

    test('saveMedicalProfile persists to the service', () async {
      final service = FakeMedicalRecordService();
      final controller = MedicalRecordsController(service);
      await controller.loadAll('user-1');

      const newProfile = MedicalProfile(
        userId: 'user-1',
        bloodGroup: 'B+',
        allergies: ['Peanuts'],
      );

      final ok = await controller.saveMedicalProfile(newProfile);
      expect(ok, isTrue);
      expect(controller.medicalProfile?.bloodGroup, 'B+');
      expect(controller.medicalProfile?.allergies, ['Peanuts']);

      // Verify it round-trips through the service.
      final fromService = await service.getMedicalProfile('user-1');
      expect(fromService?.bloodGroup, 'B+');
    });

    test('historyRecords filters correctly', () async {
      final service = FakeMedicalRecordService(
        initialRecords: [
          makeRecord(id: 'r1', category: MedicalRecordCategory.doctorVisit),
          makeRecord(id: 'r2', category: MedicalRecordCategory.medicalHistory),
          makeRecord(id: 'r3', category: MedicalRecordCategory.general),
          makeRecord(id: 'r4', category: MedicalRecordCategory.surgery),
        ],
      );
      final controller = MedicalRecordsController(service);
      await controller.loadAll('user-1');

      expect(controller.historyCount, 2); // medicalHistory + general
      expect(controller.visitCount, 1);   // doctorVisit
    });

    test('error message is set on service failure', () async {
      final service = _FailingService();
      final controller = MedicalRecordsController(service);
      await controller.loadAll('user-1');

      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, contains('Unable to load'));
      expect(controller.isLoading, isFalse);
    });
  });
}

class _FailingService extends MedicalRecordService {
  @override
  Future<List<MedicalRecord>> getRecords(String userId) async {
    throw Exception('Firestore failure');
  }

  @override
  Future<MedicalProfile?> getMedicalProfile(String userId) async {
    throw Exception('Firestore failure');
  }
}
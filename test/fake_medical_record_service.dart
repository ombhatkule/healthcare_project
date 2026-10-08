import 'package:healthcare_app/features/medical_records/models/medical_profile.dart';
import 'package:healthcare_app/features/medical_records/models/medical_record.dart';
import 'package:healthcare_app/features/medical_records/services/medical_record_service.dart';

/// An in-memory fake [MedicalRecordService] for unit and widget tests that
/// avoids the real Firestore SDK.
class FakeMedicalRecordService extends MedicalRecordService {
  FakeMedicalRecordService({
    List<MedicalRecord> initialRecords = const [],
    this.profile,
  }) : _records = List.of(initialRecords);

  final List<MedicalRecord> _records;
  MedicalProfile? profile;

  @override
  Future<List<MedicalRecord>> getRecords(String userId) async {
    return _records.where((r) => r.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<MedicalRecord?> getRecord(
      String userId, String recordId) async {
    for (final r in _records) {
      if (r.id == recordId && r.userId == userId) return r;
    }
    return null;
  }

  @override
  Future<MedicalRecord> createRecord(MedicalRecord record) async {
    final saved = record.copyWith(id: 'record-${_records.length + 1}');
    _records.add(saved);
    return saved;
  }

  @override
  Future<void> updateRecord(MedicalRecord record) async {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record.copyWith(updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> deleteRecord(String userId, String recordId) async {
    _records.removeWhere((r) => r.id == recordId && r.userId == userId);
  }

  @override
  Future<MedicalProfile?> getMedicalProfile(String userId) async {
    return profile;
  }

  @override
  Future<void> saveMedicalProfile(MedicalProfile profile) async {
    this.profile = profile;
  }
}
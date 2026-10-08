import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../models/medical_profile.dart';
import '../../models/medical_record.dart';
import '../../models/medical_record_category.dart';
import '../../services/medical_record_service.dart';

/// State management for the EHR (medical records + medical profile).
///
/// Loads the authenticated user's EHR from Firestore and exposes create /
/// update / delete / save operations. Business logic lives in
/// [MedicalRecordService]; this controller only owns UI-facing state.
class MedicalRecordsController extends ChangeNotifier {
  final MedicalRecordService _service;

  MedicalRecordsController(this._service);

  List<MedicalRecord> _records = [];
  MedicalRecord? _selectedRecord;
  MedicalProfile? _medicalProfile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<MedicalRecord> get records => List.unmodifiable(_records);
  MedicalRecord? get selectedRecord => _selectedRecord;
  MedicalProfile? get medicalProfile => _medicalProfile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Records shown under the "Medical History" section.
  List<MedicalRecord> get historyRecords => _records
      .where((r) =>
          r.category == MedicalRecordCategory.medicalHistory ||
          r.category == MedicalRecordCategory.general)
      .toList();

  /// Records shown under the "Doctor Visits" section.
  List<MedicalRecord> get visitRecords => _records
      .where((r) => r.category == MedicalRecordCategory.doctorVisit)
      .toList();

  int get historyCount => historyRecords.length;
  int get visitCount => visitRecords.length;

  /// Document attachments are not implemented in this phase.
  int get documentCount => 0;

  /// Loads the user's records and medical profile together.
  Future<void> loadAll(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getRecords(userId),
        _service.getMedicalProfile(userId),
      ]);
      _records = results[0] as List<MedicalRecord>;
      _medicalProfile = results[1] as MedicalProfile?;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Unable to load your medical records. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches a single record by [recordId] for [userId].
  Future<bool> loadRecord(String userId, String recordId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selectedRecord = await _service.getRecord(userId, recordId);
      return _selectedRecord != null;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to load this record. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new [record]. Returns true on success.
  Future<bool> createRecord(MedicalRecord record) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final saved = await _service.createRecord(record);
      _records = [saved, ..._records];
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to save this record. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Updates an existing [record] in place. Returns true on success.
  Future<bool> updateRecord(MedicalRecord record) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.updateRecord(record);
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records = List.of(_records)..[index] = record;
      } else {
        _records = [record, ..._records];
      }
      if (_selectedRecord?.id == record.id) {
        _selectedRecord = record;
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to save this record. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Deletes the record with [recordId] for [userId]. Returns true on success.
  Future<bool> deleteRecord(String userId, String recordId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.deleteRecord(userId, recordId);
      _records = _records.where((r) => r.id != recordId).toList();
      if (_selectedRecord?.id == recordId) {
        _selectedRecord = null;
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to delete this record.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Saves the structured [MedicalProfile]. Returns true on success.
  Future<bool> saveMedicalProfile(MedicalProfile profile) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.saveMedicalProfile(profile);
      _medicalProfile = profile;
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to save your medical information. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
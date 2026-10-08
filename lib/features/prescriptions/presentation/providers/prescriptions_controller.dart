import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../models/prescription.dart';
import '../../models/prescription_status.dart';
import '../../services/prescription_service.dart';

/// State management for prescriptions.
///
/// Loads the authenticated user's prescriptions from Firestore and exposes
/// create / update / delete operations plus simple search filtering. Business
/// logic lives in [PrescriptionService]; this controller only owns UI-facing
/// state.
class PrescriptionsController extends ChangeNotifier {
  final PrescriptionService _service;

  PrescriptionsController(this._service);

  List<Prescription> _prescriptions = [];
  Prescription? _selectedPrescription;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Prescription> get prescriptions => List.unmodifiable(_prescriptions);
  Prescription? get selectedPrescription => _selectedPrescription;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String get searchQuery => _searchQuery;

  /// Prescriptions that are currently active.
  List<Prescription> get activePrescriptions =>
      _whereStatus(PrescriptionStatus.active);

  /// Prescriptions that are completed / previous.
  List<Prescription> get previousPrescriptions =>
      _whereStatus(PrescriptionStatus.completed);

  /// All prescriptions filtered by the active search query.
  List<Prescription> get filteredPrescriptions => _filter(_prescriptions);

  /// Active prescriptions filtered by the active search query.
  List<Prescription> get filteredActivePrescriptions =>
      _filter(_whereStatus(PrescriptionStatus.active));

  /// Previous prescriptions filtered by the active search query.
  List<Prescription> get filteredPreviousPrescriptions =>
      _filter(_whereStatus(PrescriptionStatus.completed));

  /// Sets the search query (matches doctor name or medicine name).
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  List<Prescription> _whereStatus(PrescriptionStatus status) {
    return _prescriptions.where((p) => p.status == status).toList();
  }

  List<Prescription> _filter(List<Prescription> source) {
    if (_searchQuery.isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source.where((p) {
      final doctorHit = p.doctorName.toLowerCase().contains(q) ||
          p.doctorSpecialty.toLowerCase().contains(q);
      final medicineHit = p.medicines.any(
        (m) => m.medicineName.toLowerCase().contains(q),
      );
      return doctorHit || medicineHit;
    }).toList();
  }

  /// Loads all prescriptions for the authenticated [userId].
  Future<void> loadAll(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _prescriptions = await _service.getPrescriptions(userId);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Unable to load your prescriptions. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches a single prescription by [prescriptionId] for [userId].
  Future<bool> loadPrescription(String userId, String prescriptionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selectedPrescription =
          await _service.getPrescription(userId, prescriptionId);
      return _selectedPrescription != null;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to load this prescription. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new [prescription]. Returns true on success.
  Future<bool> createPrescription(Prescription prescription) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final saved = await _service.createPrescription(prescription);
      _prescriptions = [saved, ..._prescriptions];
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to save the prescription. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Updates an existing [prescription] in place. Returns true on success.
  Future<bool> updatePrescription(Prescription prescription) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.updatePrescription(prescription);
      final index = _prescriptions.indexWhere((p) => p.id == prescription.id);
      if (index != -1) {
        _prescriptions = List.of(_prescriptions)..[index] = prescription;
      } else {
        _prescriptions = [prescription, ..._prescriptions];
      }
      if (_selectedPrescription?.id == prescription.id) {
        _selectedPrescription = prescription;
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to save the prescription. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Deletes the prescription with [prescriptionId] for [userId].
  /// Returns true on success.
  Future<bool> deletePrescription(String userId, String prescriptionId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.deletePrescription(userId, prescriptionId);
      _prescriptions =
          _prescriptions.where((p) => p.id != prescriptionId).toList();
      if (_selectedPrescription?.id == prescriptionId) {
        _selectedPrescription = null;
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to delete the prescription.';
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
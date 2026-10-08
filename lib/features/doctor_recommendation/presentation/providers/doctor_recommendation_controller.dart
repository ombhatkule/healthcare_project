import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/constants.dart';
import '../../models/disease_specialty_mapping.dart';
import '../../models/doctor.dart';
import '../../models/specialty_summary.dart';
import '../../services/doctor_recommendation_service.dart';

/// Controller for the Doctor Recommendation flow.
///
/// Owns the currently active predicted disease (or browsed specialty), the
/// recommended specialty, the loaded doctor list and the browsing summaries,
/// plus loading/error state. Talks only to [DoctorRecommendationService].
class DoctorRecommendationController extends ChangeNotifier {
  final DoctorRecommendationService _service;

  DoctorRecommendationController(this._service);

  String? _predictedDisease;
  String? _activeSpecialty;
  List<Doctor> _doctors = const [];
  List<SpecialtySummary> _specialties = const [];
  bool _isLoading = false;
  String? _errorMessage;

  String? get predictedDisease => _predictedDisease;
  String? get activeSpecialty => _activeSpecialty;
  List<Doctor> get doctors => List.unmodifiable(_doctors);
  List<SpecialtySummary> get specialties => List.unmodifiable(_specialties);
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  /// True when a prediction context is active (vs. plain specialty browsing).
  bool get isFromPrediction => _predictedDisease != null;

  /// The recommended specialty for the current context.
  String get recommendedSpecialty =>
      _activeSpecialty ?? DiseaseSpecialtyMapping.fallbackSpecialty;

  /// Loads doctors for the condition predicted by the disease-prediction flow.
  Future<void> loadForDisease(String? disease) async {
    final specialty = DiseaseSpecialtyMapping.recommendedSpecialty(disease);
    _predictedDisease = (disease == null || disease.trim().isEmpty)
        ? null
        : disease.trim();
    _activeSpecialty = specialty;
    await _fetchDoctors(specialty);
  }

  /// Loads doctors for a directly-chosen specialty (Find a Doctor browsing).
  Future<void> loadForSpecialty(String specialty) async {
    _predictedDisease = null;
    _activeSpecialty = specialty;
    await _fetchDoctors(specialty);
  }

  /// Loads the specialty summaries used by the "Find a Doctor" entry screen.
  Future<void> loadSpecialtySummaries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _specialties = List.unmodifiable(
        await _service.getSpecialtySummaries(),
      );
    } catch (_) {
      _errorMessage = AppStrings.specialtiesLoadFailed;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-runs the most recent load (used by retry/error states).
  Future<void> retry() async {
    if (isFromPrediction) {
      await loadForDisease(_predictedDisease);
    } else if (_activeSpecialty != null) {
      await loadForSpecialty(_activeSpecialty!);
    } else {
      await loadSpecialtySummaries();
    }
  }

  Future<void> _fetchDoctors(String specialty) async {
    _isLoading = true;
    _errorMessage = null;
    _doctors = const [];
    notifyListeners();

    try {
      _doctors = List.unmodifiable(
        await _service.getDoctorsBySpecialty(specialty),
      );
    } catch (_) {
      _errorMessage = AppStrings.doctorsLoadFailed;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
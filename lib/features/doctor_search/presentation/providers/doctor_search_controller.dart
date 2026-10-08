import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/constants.dart';
import '../../../doctor_recommendation/models/doctor.dart';
import '../../../doctor_recommendation/services/doctor_recommendation_service.dart';

/// Controller for the Doctor Search screen.
///
/// Owns the search text (debounced), the active specialty/location/rating
/// filters, the sort order, the result list and the loading/error state.
/// Talks only to [DoctorRecommendationService].
class DoctorSearchController extends ChangeNotifier {
  DoctorSearchController(this._service);

  static const Duration _debounceDuration = Duration(milliseconds: 250);

  final DoctorRecommendationService _service;
  Timer? _debounce;

  String _query = '';
  String _selectedSpecialty = '';
  String _selectedLocation = '';
  double _minRating = 0;
  DoctorSort _sort = DoctorSort.recommended;
  List<Doctor> _results = const [];
  List<String> _specialties = const [];
  List<String> _locations = const [];
  bool _isLoading = false;
  bool _isOptionsLoading = false;
  String? _errorMessage;

  String get query => _query;
  String get selectedSpecialty => _selectedSpecialty;
  String get selectedLocation => _selectedLocation;
  double get minRating => _minRating;
  DoctorSort get sort => _sort;
  List<Doctor> get results => List.unmodifiable(_results);
  List<String> get specialties => List.unmodifiable(_specialties);
  List<String> get locations => List.unmodifiable(_locations);
  bool get isLoading => _isLoading;
  bool get isOptionsLoading => _isOptionsLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  /// True when at least one filter or a non-empty query is active.
  bool get hasActiveFilters =>
      _query.trim().isNotEmpty ||
      _selectedSpecialty.isNotEmpty ||
      _selectedLocation.isNotEmpty ||
      _minRating > 0 ||
      _sort != DoctorSort.recommended;

  /// Initializes the filter options and runs the initial full search.
  Future<void> initialize() async {
    await _loadOptions();
    await _search();
  }

  Future<void> _loadOptions() async {
    _isOptionsLoading = true;
    notifyListeners();
    try {
      final summaries = await _service.getSpecialtySummaries();
      final locations = await _service.getLocations();
      _specialties = List.unmodifiable(
        summaries.where((s) => s.doctorCount > 0).map((s) => s.specialty),
      );
      _locations = locations;
    } finally {
      _isOptionsLoading = false;
      notifyListeners();
    }
  }

  /// Sets the search text. Searches are debounced so a request is not fired
  /// for every character typed.
  void updateQuery(String value) {
    _query = value;
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _search());
  }

  void setSpecialty(String value) {
    _selectedSpecialty = value;
    _runImmediate();
  }

  void setLocation(String value) {
    _selectedLocation = value;
    _runImmediate();
  }

  void setMinRating(double value) {
    _minRating = value;
    _runImmediate();
  }

  void setSort(DoctorSort value) {
    _sort = value;
    _runImmediate();
  }

  void _runImmediate() {
    _debounce?.cancel();
    _search();
  }

  /// Resets every filter and the query, then reloads all doctors.
  Future<void> clearFilters() async {
    _debounce?.cancel();
    _query = '';
    _selectedSpecialty = '';
    _selectedLocation = '';
    _minRating = 0;
    _sort = DoctorSort.recommended;
    notifyListeners();
    await _search();
  }

  /// Re-runs the search (used by retry/error states).
  Future<void> retry() async {
    _errorMessage = null;
    await initialize();
  }

  Future<void> _search() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _results = List.unmodifiable(
        await _service.searchDoctors(
          query: _query,
          specialty: _selectedSpecialty,
          location: _selectedLocation,
          minRating: _minRating,
          sort: _sort,
        ),
      );
    } catch (_) {
      _errorMessage = AppStrings.doctorsLoadFailed;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
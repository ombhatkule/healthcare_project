import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/constants/constants.dart';
import '../../models/mock_prediction_history.dart';
import '../../models/prediction_history.dart';
import '../../models/prediction_result.dart';
import '../../models/symptom.dart';
import '../../services/disease_prediction_service.dart';

/// Controller (ChangeNotifier) for the Disease Prediction flow.
///
/// Owns the UI state: the symptom catalog (served by the backend via
/// [DiseasePredictionService.fetchSymptoms]), the selected symptoms, the
/// search query, the current prediction result and loading/error state, plus
/// the (mock) prediction history. It talks only to [DiseasePredictionService].
class DiseasePredictionController extends ChangeNotifier {
  final DiseasePredictionService _service;

  DiseasePredictionController(this._service) {
    unawaited(loadSymptoms());
  }

  List<Symptom> _catalog = const [];
  bool _isCatalogLoading = true;
  String? _catalogError;

  final List<Symptom> _selectedSymptoms = [];
  final List<PredictionHistory> _history = [...MockPredictionHistoryData.items];

  String _searchQuery = '';
  bool _isPredicting = false;
  String? _errorMessage;
  PredictionResult? _result;

  List<Symptom> get selectedSymptoms =>
      List.unmodifiable(_selectedSymptoms);

  List<PredictionHistory> get history => List.unmodifiable(_history);

  /// The full symptom catalog fetched from the backend (single source of
  /// truth for the selectable symptoms).
  List<Symptom> get catalog => List.unmodifiable(_catalog);

  bool get isCatalogLoading => _isCatalogLoading;
  bool get hasCatalogError => _catalogError != null;
  String? get catalogError => _catalogError;

  /// Loads (or, on failure, retries loading) the backend symptom catalog.
  Future<void> loadSymptoms() async {
    _isCatalogLoading = true;
    _catalogError = null;
    notifyListeners();
    try {
      final symptoms = await _service.fetchSymptoms();
      _catalog = List.unmodifiable(symptoms);
    } on PredictionException catch (e) {
      _catalogError = e.message;
    } catch (_) {
      _catalogError = AppStrings.symptomsFailedToLoad;
    } finally {
      _isCatalogLoading = false;
      notifyListeners();
    }
  }

  /// Retries loading the symptom catalog after a failure.
  Future<void> retryLoadSymptoms() => loadSymptoms();

  /// Symptoms matching the current search query.
  List<Symptom> get filteredSymptoms => _searchSymptoms(_searchQuery);

  String get searchQuery => _searchQuery;

  bool get isPredicting => _isPredicting;
  String? get errorMessage => _errorMessage;
  PredictionResult? get result => _result;
  bool get hasError => _errorMessage != null;

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Toggle a symptom in/out of the selected list.
  void toggleSymptom(Symptom symptom) {
    if (_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.remove(symptom);
    } else {
      _selectedSymptoms.add(symptom);
    }
    notifyListeners();
  }

  bool isSelected(Symptom symptom) => _selectedSymptoms.contains(symptom);

  /// Remove an individual selected symptom.
  void removeSymptom(Symptom symptom) {
    _selectedSymptoms.remove(symptom);
    notifyListeners();
  }

  /// Runs a prediction for the currently selected symptoms.
  ///
  /// Validates input first (no request is made for an empty selection) and
  /// ignores new requests while a prediction is already running. On success
  /// the [result] is set; the controller makes no claim that the result is a
  /// real diagnosis — callers must render it as informational only.
  ///
  /// The symptom values are converted to backend-compatible IDs inside the
  /// service; the controller only orchestrates loading, storage and errors.
  Future<void> predict() async {
    if (_isPredicting) return;

    _errorMessage = null;
    if (_selectedSymptoms.isEmpty) {
      _errorMessage = AppStrings.noSymptomsSelected;
      notifyListeners();
      return;
    }

    _isPredicting = true;
    _result = null;
    notifyListeners();

    try {
      final prediction = await _service.predict(
        List.unmodifiable(_selectedSymptoms),
      );
      _result = prediction;
      _prependHistory(prediction);
    } on PredictionException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = AppStrings.predictionFailure;
    } finally {
      _isPredicting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear the selection, the search, the result, and any error — returning
  /// the controller to the symptom-selection state.
  void reset() {
    _selectedSymptoms.clear();
    _searchQuery = '';
    _result = null;
    _errorMessage = null;
    _isPredicting = false;
    notifyListeners();
  }

  void _prependHistory(PredictionResult prediction) {
    _history.insert(
      0,
      PredictionHistory(
        date: DateTime.now(),
        symptoms: List.unmodifiable(prediction.selectedSymptoms),
        prediction: prediction.prediction,
        isDemo: prediction.isDemo,
      ),
    );
  }

  /// Returns symptoms in the catalog whose name contains [query]
  /// (case-insensitive). Falls back to an empty list while the catalog is
  /// still loading.
  List<Symptom> _searchSymptoms(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_catalog);
    return _catalog
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.id.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }
}

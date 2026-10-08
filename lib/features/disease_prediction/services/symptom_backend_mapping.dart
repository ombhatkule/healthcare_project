import '../models/symptom.dart';

/// Legacy mapping between UI display-style symptom IDs and the model symptom
/// namespace of the original Phase 7C model (`symptom_*` names).
///
/// IMPORTANT (Phase 7J): this mapping is NO LONGER USED by the production
/// [FlaskDiseasePredictionService]. The UI catalog is now fetched directly
/// from the backend `GET /api/symptoms` endpoint, so symptom IDs ARE the
/// canonical backend names and are sent to `POST /api/predict` unchanged.
///
/// This file is kept only as a reference to the old 7C-era contract; it must
/// not be re-introduced as the source of truth for symptom IDs.
abstract final class SymptomBackendMapping {
  /// Explicit overrides for UI symptom IDs whose canonical backend name differs
  /// from a simple `symptom_<normalized-id>` derivation.
  static const Map<String, String> _overrides = {
    'joint-pain': 'symptom_joint_pain_symptom',
  };

  /// Returns the backend-compatible symptom ID for [symptom].
  static String toBackendId(Symptom symptom) {
    // Already a canonical backend name (e.g. fetched from GET /api/symptoms).
    if (symptom.id.startsWith('symptom_')) return symptom.id;

    final explicit = _overrides[symptom.id];
    if (explicit != null) return explicit;

    // Normalize display-style IDs: lowercase, hyphens/whitespace -> underscore,
    // then prefix with the canonical 'symptom_' namespace used by the model.
    final normalized = symptom.id
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
    return 'symptom_$normalized';
  }
}
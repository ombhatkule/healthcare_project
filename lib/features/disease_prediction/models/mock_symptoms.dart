import 'symptom.dart';

/// Provides the mock symptom catalog used ONLY by unit tests / the demo.
///
/// IMPORTANT (Phase 7J): the production catalog is served by the backend via
/// `GET /api/symptoms` and is the single source of truth for selectable
/// symptoms. This small hand-written list is kept purely so unit tests and
/// MockPredictionService have a deterministic fixture. It does NOT reflect the
/// model vocabulary (e.g. ids like `muscle-pain` do not exist in the backend).
abstract final class MockSymptoms {
  static const List<Symptom> all = [
    Symptom(id: 'fever', name: 'Fever'),
    Symptom(id: 'cough', name: 'Cough'),
    Symptom(id: 'headache', name: 'Headache'),
    Symptom(id: 'fatigue', name: 'Fatigue'),
    Symptom(id: 'nausea', name: 'Nausea'),
    Symptom(id: 'vomiting', name: 'Vomiting'),
    Symptom(id: 'sore-throat', name: 'Sore throat'),
    Symptom(id: 'nasal-congestion', name: 'Nasal congestion'),
    Symptom(id: 'chest-pain', name: 'Chest pain'),
    Symptom(id: 'abdominal-pain', name: 'Abdominal pain'),
    Symptom(id: 'shortness-of-breath', name: 'Shortness of breath'),
    Symptom(id: 'dizziness', name: 'Dizziness'),
    Symptom(id: 'joint-pain', name: 'Joint pain'),
    Symptom(id: 'muscle-pain', name: 'Muscle pain'),
    Symptom(id: 'runny-nose', name: 'Runny nose'),
    Symptom(id: 'loss-of-appetite', name: 'Loss of appetite'),
  ];

  /// Returns symptoms whose name contains [query] (case-insensitive).
  static List<Symptom> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) => s.name.toLowerCase().contains(q))
        .toList(growable: false);
  }
}

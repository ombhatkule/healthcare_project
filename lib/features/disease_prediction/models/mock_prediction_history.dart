import 'prediction_history.dart';
import 'symptom.dart';

/// Provides **mock** prediction history for the Phase 5 UI.
///
/// IMPORTANT: This is placeholder / demo data only — it is NOT stored in
/// Firestore and is NOT real user history. Persistence will be added in a
/// later phase. This class keeps the mock clearly separated from any real
/// database functionality.
abstract final class MockPredictionHistoryData {
  static final List<PredictionHistory> items = [
    PredictionHistory(
      date: DateTime(2026, 9, 3),
      symptoms: const [
        Symptom(id: 'fever', name: 'Fever'),
        Symptom(id: 'cough', name: 'Cough'),
        Symptom(id: 'headache', name: 'Headache'),
        Symptom(id: 'fatigue', name: 'Fatigue'),
        Symptom(id: 'sore-throat', name: 'Sore throat'),
      ],
      prediction: 'Demo Prediction',
    ),
    PredictionHistory(
      date: DateTime(2026, 9, 1),
      symptoms: const [
        Symptom(id: 'headache', name: 'Headache'),
        Symptom(id: 'dizziness', name: 'Dizziness'),
        Symptom(id: 'fatigue', name: 'Fatigue'),
      ],
      prediction: 'Demo Prediction',
    ),
  ];
}

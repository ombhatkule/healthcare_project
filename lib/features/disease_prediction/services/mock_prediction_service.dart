import '../models/mock_symptoms.dart';
import '../models/prediction_result.dart';
import '../models/symptom.dart';
import 'disease_prediction_service.dart';

/// A mock implementation of [DiseasePredictionService].
///
/// IMPORTANT:
///  - This returns DEMO data only for UI development and unit tests.
///  - The result is always flagged [PredictionResult.isDemo] == true and is
///    clearly marked in the UI as a "Demo / Mock Prediction".
///  - No real ML model runs here and no medical accuracy is claimed.
///  - The symptom catalog comes from [MockSymptoms], a small hand-written list
///    used for tests; the production catalog is served by the backend.
class MockPredictionService implements DiseasePredictionService {
  @override
  Future<List<Symptom>> fetchSymptoms() async =>
      List.unmodifiable(MockSymptoms.all);

  @override
  Future<PredictionResult> predict(List<Symptom> symptoms) async {
    // Simulate a short analysis delay so the loading state is visible.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    return PredictionResult(
      prediction: 'Example Prediction',
      confidence: 82,
      selectedSymptoms: List.unmodifiable(symptoms),
      possibleConditions: const [
        'Example Condition 1',
        'Example Condition 2',
      ],
      isDemo: true,
    );
  }
}

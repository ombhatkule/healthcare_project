import '../models/prediction_result.dart';
import '../models/symptom.dart';

/// Thrown by [DiseasePredictionService] implementations when a prediction
/// cannot be completed. The [message] is safe to show to the user.
class PredictionException implements Exception {
  final String message;

  const PredictionException(this.message);

  @override
  String toString() => message;
}

/// Contract for the disease prediction service.
///
/// The UI / controller depends on this abstract type. It is implemented by
/// [MockPredictionService] (demo data only) for unit tests and by
/// [FlaskDiseasePredictionService] in production:
///
///   UI -> Controller -> DiseasePredictionService -> (Mock | Flask API)
abstract class DiseasePredictionService {
  /// Fetches the symptom catalog served by the backend.
  ///
  /// This is the single source of truth for the selectable symptoms: the UI
  /// must present exactly the vocabulary the active model supports, in the
  /// order returned by the backend.
  ///
  /// Throws a [PredictionException] with a user-friendly message when the
  /// catalog cannot be retrieved (network failure, backend error, etc).
  Future<List<Symptom>> fetchSymptoms();

  /// Creates a prediction from the given [symptoms].
  ///
  /// [symptoms] must not be empty (callers validate before calling).
  ///
  /// Throws a [PredictionException] with a user-friendly message when the
  /// prediction cannot be completed (network failure, backend error, etc).
  Future<PredictionResult> predict(List<Symptom> symptoms);
}

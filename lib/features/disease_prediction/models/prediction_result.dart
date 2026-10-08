import 'symptom.dart';

/// A single disease entry returned in the `top_predictions` list of the
/// Flask `/api/predict` response.
///
/// The [score] is the raw output of the experimental research/educational
/// model. It is NOT a calibrated or medically validated probability and must
/// never be presented as diagnostic confidence.
class TopPrediction {
  final String disease;
  final double score;

  const TopPrediction({required this.disease, required this.score});

  factory TopPrediction.fromJson(Map<String, dynamic> json) {
    return TopPrediction(
      disease: (json['disease'] as String?) ?? 'Unknown',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Score formatted as a percentage of the raw model output (e.g. "2.86%").
  String get scoreLabel => '${(score * 100).toStringAsFixed(2)}%';
}

/// The result of a disease prediction.
///
/// Mock results come from [MockPredictionService] and keep the legacy demo
/// fields ([confidence], [possibleConditions], [isDemo]). Real results come
/// from the Flask `/api/predict` endpoint and populate [score],
/// [topPredictions] and [disclaimer] instead.
///
/// IMPORTANT: Result values are model outputs for informational purposes only
/// and must never be presented as a confirmed medical diagnosis.
class PredictionResult {
  /// Display name of the predicted (possible) condition.
  final String prediction;

  /// The symptoms that were selected for this prediction.
  final List<Symptom> selectedSymptoms;

  /// Whether this result is a mock/demo value.
  final bool isDemo;

  /// Legacy mock confidence (integer percentage). Only meaningful for demo
  /// results; real results carry a raw model [score] instead.
  final int confidence;

  /// Legacy mock list of possible conditions. Only populated for demo results.
  final List<String> possibleConditions;

  /// Raw experimental model score for the top prediction (0..1). Null for
  /// demo results. NOT a calibrated probability.
  final double? score;

  /// Ordered list of top predicted conditions with their raw model scores.
  final List<TopPrediction> topPredictions;

  /// Disclaimer returned by the Flask backend about score calibration.
  final String? disclaimer;

  const PredictionResult({
    required this.prediction,
    required this.selectedSymptoms,
    required this.confidence,
    required this.possibleConditions,
    this.isDemo = true,
    this.score,
    this.topPredictions = const [],
    this.disclaimer,
  });

  /// Parses a successful Flask `POST /api/predict` response body.
  factory PredictionResult.fromFlaskResponse(
    Map<String, dynamic> json, {
    required List<Symptom> selectedSymptoms,
  }) {
    final prediction =
        (json['prediction'] as Map<String, dynamic>?) ?? const {};
    final top = (json['top_predictions'] as List<dynamic>?) ?? const [];

    return PredictionResult(
      prediction: (prediction['disease'] as String?) ?? 'Unknown',
      selectedSymptoms: List.unmodifiable(selectedSymptoms),
      confidence: 0,
      possibleConditions: const [],
      isDemo: false,
      score: (prediction['score'] as num?)?.toDouble(),
      topPredictions: List.unmodifiable(
        top
            .whereType<Map<String, dynamic>>()
            .map(TopPrediction.fromJson),
      ),
      disclaimer: json['disclaimer'] as String?,
    );
  }

  /// Demo percentages are "Confidence"; real results are "Model score".
  String get confidenceLabel => '$confidence%';

  /// Raw model score formatted as a percentage (e.g. "2.86%"). Only set when
  /// [score] is present.
  String get modelScoreLabel {
    final s = score;
    if (s == null) return confidenceLabel;
    return '${(s * 100).toStringAsFixed(2)}%';
  }
}
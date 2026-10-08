import 'symptom.dart';

/// A single entry in the prediction history list.
///
/// NOTE: History is NOT persisted to Firestore yet (that lands in a later
/// phase). The history shown comes from clearly separated mock data.
class PredictionHistory {
  final DateTime date;
  final List<Symptom> symptoms;
  final String prediction;
  final bool isDemo;

  const PredictionHistory({
    required this.date,
    required this.symptoms,
    required this.prediction,
    this.isDemo = true,
  });

  int get symptomCount => symptoms.length;
}

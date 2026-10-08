/// A summary of the user's health metrics for display on the dashboard.
///
/// NOTE: This is a **mock** data holder for Phase 3 only. No medical
/// calculations are performed; values are placeholders until the health
/// tracking features are implemented in later phases.
class HealthSummaryModel {
  final double? bmi;
  final DateTime? lastHealthCheck;
  final int medicalRecordsCount;

  const HealthSummaryModel({
    this.bmi,
    this.lastHealthCheck,
    this.medicalRecordsCount = 0,
  });

  /// A friendly label for BMI, or null if not available.
  String get bmiLabel => bmi != null ? bmi!.toStringAsFixed(1) : '--';

  /// A friendly label for the last health check, or null if unavailable.
  String get lastCheckLabel =>
      lastHealthCheck != null ? _formatDate(lastHealthCheck!) : 'Not recorded';

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

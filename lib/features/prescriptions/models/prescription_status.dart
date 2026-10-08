/// Simple lifecycle status for a prescription record.
///
/// The status describes the record only (active/completed) and never provides
/// medical advice or medication-management logic.
enum PrescriptionStatus {
  active,
  completed;

  /// A human-readable label for the status.
  String get label => switch (this) {
        PrescriptionStatus.active => 'Active',
        PrescriptionStatus.completed => 'Completed',
      };

  /// Parses a stored status name, falling back to [active].
  static PrescriptionStatus parse(String? value) {
    if (value == null) return PrescriptionStatus.active;
    return PrescriptionStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PrescriptionStatus.active,
    );
  }
}
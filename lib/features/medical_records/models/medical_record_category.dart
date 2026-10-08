/// Categories a [MedicalRecord] can belong to.
///
/// The list is extensible: unknown values read back from Firestore fall back
/// to [general] so older data never breaks the UI.
enum MedicalRecordCategory {
  general,
  medicalHistory,
  surgery,
  doctorVisit,
  labTest,
  other;

  /// A human-readable label for the category.
  String get label => switch (this) {
        MedicalRecordCategory.general => 'General',
        MedicalRecordCategory.medicalHistory => 'Medical History',
        MedicalRecordCategory.surgery => 'Surgery',
        MedicalRecordCategory.doctorVisit => 'Doctor Visit',
        MedicalRecordCategory.labTest => 'Lab/Test',
        MedicalRecordCategory.other => 'Other',
      };

  /// Parses a stored category name, falling back to [general].
  static MedicalRecordCategory parse(String? value) {
    if (value == null) return MedicalRecordCategory.general;
    return MedicalRecordCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => MedicalRecordCategory.general,
    );
  }
}
/// A single structured medicine entry inside a prescription.
///
/// Medicines are kept as structured fields (name, dosage, frequency, duration,
/// instructions) so the prescription data remains readable by later phases
/// (AI Assistant explanations, QR medical records) without storing everything
/// as an unstructured string.
class Medicine {
  final String id;
  final String medicineName;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  const Medicine({
    this.id = '',
    required this.medicineName,
    this.dosage = '',
    this.frequency = '',
    this.duration = '',
    this.instructions = '',
  });

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: (map['id'] as String?) ?? '',
      medicineName: (map['medicineName'] as String?) ?? '',
      dosage: (map['dosage'] as String?) ?? '',
      frequency: (map['frequency'] as String?) ?? '',
      duration: (map['duration'] as String?) ?? '',
      instructions: (map['instructions'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }

  Medicine copyWith({
    String? id,
    String? medicineName,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
  }) {
    return Medicine(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
    );
  }
}
/// A user-entered past surgery stored as part of the medical profile.
///
/// Surgeries are kept as structured list entries inside the
/// `users/{userId}/medical_profile` document (not free-form text) so future
/// phases can consume them reliably.
class PastSurgery {
  final String name;
  final int? year;
  final String hospital;
  final String notes;

  const PastSurgery({
    required this.name,
    this.year,
    this.hospital = '',
    this.notes = '',
  });

  factory PastSurgery.fromMap(Map<String, dynamic> map) {
    return PastSurgery(
      name: (map['name'] as String?) ?? '',
      year: (map['year'] as num?)?.toInt(),
      hospital: (map['hospital'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (year != null) 'year': year,
      'hospital': hospital,
      'notes': notes,
    };
  }

  PastSurgery copyWith({
    String? name,
    int? year,
    String? hospital,
    String? notes,
  }) {
    return PastSurgery(
      name: name ?? this.name,
      year: year ?? this.year,
      hospital: hospital ?? this.hospital,
      notes: notes ?? this.notes,
    );
  }
}
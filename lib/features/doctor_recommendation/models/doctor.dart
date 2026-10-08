/// A healthcare professional recommended for a predicted condition.
///
/// Placeholder data used here is mock/realistic only; the real doctor catalog
/// will be wired to a backend in a future phase.
class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String qualification;
  final int experienceYears;
  final String hospital;
  final String location;
  final int consultationFee;
  final double rating;
  final int reviewCount;
  final bool availableToday;
  final List<String> languages;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.qualification,
    required this.experienceYears,
    required this.hospital,
    required this.location,
    required this.consultationFee,
    required this.rating,
    required this.reviewCount,
    required this.availableToday,
    this.languages = const [],
  });

  /// Initials carved from the doctor name, e.g. "AS" for "Dr. Aarti Sharma".
  String get initials {
    final cleaned = name.replaceAll('Dr. ', '').trim();
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  /// Best-effort city extracted from [location], e.g. "Nagar Road, Pune" -> "Pune".
  String get city {
    final index = location.lastIndexOf(',');
    if (index == -1) return location.trim();
    return location.substring(index + 1).trim();
  }

  String get feeLabel => '₹$consultationFee';

  @override
  bool operator ==(Object other) => other is Doctor && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
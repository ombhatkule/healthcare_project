/// A browseable specialty together with the number of available doctors.
class SpecialtySummary {
  final String specialty;
  final int doctorCount;

  const SpecialtySummary({required this.specialty, required this.doctorCount});

  String get countLabel => doctorCount == 1 ? '1 doctor' : '$doctorCount doctors';
}
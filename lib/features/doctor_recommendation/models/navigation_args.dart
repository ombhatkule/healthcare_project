import 'doctor.dart';

/// Arguments handed to the Doctor Recommendation screen via route arguments.
///
/// Either a [predictedDisease] (from the prediction result flow) or a
/// browseable [specialty] (from the "Find a Doctor" entry) can be supplied.
/// When both are present the predicted disease takes precedence.
class DoctorRecommendationArgs {
  final String? predictedDisease;
  final String? specialty;

  const DoctorRecommendationArgs({this.predictedDisease, this.specialty});

  factory DoctorRecommendationArgs.forSpecialty(String specialty) =>
      DoctorRecommendationArgs(specialty: specialty);
}

/// Arguments handed to the Doctor Details screen via route arguments.
class DoctorDetailsArgs {
  final Doctor doctor;

  const DoctorDetailsArgs({required this.doctor});
}
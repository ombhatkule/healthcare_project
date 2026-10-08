import '../models/doctor.dart';
import '../models/specialty_summary.dart';

/// How search results should be ordered.
enum DoctorSort {
  /// Default ordering: available doctors first, then by rating.
  recommended,

  /// Highest rated doctors first.
  highestRated,

  /// Most experienced doctors first.
  mostExperienced,
}

/// Contract for the doctor recommendation/data source.
///
/// Currently backed by [MockDoctorRepository]; swapping in a real backend only
/// requires a new implementation of this interface.
abstract class DoctorRecommendationService {
  /// Returns the doctors available for [specialty].
  ///
  /// Matching is case-insensitive. An empty list is returned when no doctor
  /// matches the specialty.
  Future<List<Doctor>> getDoctorsBySpecialty(String specialty);

  /// All supported specialties with the number of doctors available.
  Future<List<SpecialtySummary>> getSpecialtySummaries();

  /// Returns a single doctor by [id], or null when not found.
  Future<Doctor?> getDoctorById(String id);

  /// Distinct cities present in the catalog (used for the location filter),
  /// sorted alphabetically and derived from the actual doctor data.
  Future<List<String>> getLocations();

  /// Searches doctors using all active filters combined with AND logic.
  ///
  /// [query] is matched (case-insensitively, substring) against the doctor
  /// name, specialty, hospital and location. [specialty] and [location]
  /// further narrow the results; an empty value means "no filter".
  /// [minRating] keeps only doctors rated at least that high.
  /// Results are ordered per [sort].
  Future<List<Doctor>> searchDoctors({
    String query = '',
    String specialty = '',
    String location = '',
    double minRating = 0,
    DoctorSort sort = DoctorSort.recommended,
  });
}

/// Shared search logic so any backend implementation behaves identically.
abstract class DoctorSearchHelper {
  /// True when [doctor] matches [query] on name/specialty/hospital/location.
  static bool matchesQuery(Doctor doctor, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final fields = [
      doctor.name,
      doctor.specialty,
      doctor.qualification,
      doctor.hospital,
      doctor.location,
      doctor.city,
    ];
    return fields.any((value) => value.toLowerCase().contains(q));
  }

  /// True when [doctor] matches the selected specialty (empty = no filter).
  static bool matchesSpecialty(Doctor doctor, String specialty) {
    final s = specialty.trim().toLowerCase();
    if (s.isEmpty) return true;
    return doctor.specialty.toLowerCase() == s;
  }

  /// True when [doctor] belongs to the selected city (empty = no filter).
  static bool matchesLocation(Doctor doctor, String location) {
    final l = location.trim().toLowerCase();
    if (l.isEmpty) return true;
    return doctor.city.toLowerCase() == l;
  }

  /// True when [doctor] rating meets the threshold.
  static bool matchesMinRating(Doctor doctor, double minRating) {
    return doctor.rating >= minRating;
  }

  /// Applies [sort] ordering to [doctors] (in place).
  static void sortDoctors(List<Doctor> doctors, DoctorSort sort) {
    switch (sort) {
      case DoctorSort.recommended:
        doctors.sort((a, b) {
          final availability = (b.availableToday ? 1 : 0) - (a.availableToday ? 1 : 0);
          if (availability != 0) return availability;
          return b.rating.compareTo(a.rating);
        });
      case DoctorSort.highestRated:
        doctors.sort((a, b) => b.rating.compareTo(a.rating));
      case DoctorSort.mostExperienced:
        doctors.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
    }
  }
}
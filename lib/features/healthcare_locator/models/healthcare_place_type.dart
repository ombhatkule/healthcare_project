import 'package:flutter/material.dart';

/// The kind of healthcare facility a [HealthcarePlace] represents.
enum HealthcarePlaceType {
  hospital(
    singular: 'Hospital',
    plural: 'Hospitals',
    icon: Icons.local_hospital_outlined,
  ),
  pharmacy(
    singular: 'Pharmacy',
    plural: 'Pharmacies',
    icon: Icons.local_pharmacy_outlined,
  );

  const HealthcarePlaceType({
    required this.singular,
    required this.plural,
    required this.icon,
  });

  /// Human readable singular label, e.g. "Hospital".
  final String singular;

  /// Human readable plural label, e.g. "Hospitals".
  final String plural;

  /// Icon representing the place type.
  final IconData icon;

  /// Maps an OpenStreetMap `amenity` tag value to a place type, or null when
  /// the value is not one this feature supports.
  static HealthcarePlaceType? fromOsmAmenity(String? amenity) {
    switch (amenity) {
      case 'hospital':
        return HealthcarePlaceType.hospital;
      case 'pharmacy':
        return HealthcarePlaceType.pharmacy;
      default:
        return null;
    }
  }

  /// The OpenStreetMap tag value used for this type.
  String get osmValue => name;
}
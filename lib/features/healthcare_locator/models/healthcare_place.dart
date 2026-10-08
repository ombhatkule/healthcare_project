import '../utils/geo_utils.dart';
import 'geo_point.dart';
import 'healthcare_place_type.dart';

/// A single hospital or pharmacy returned by the OpenStreetMap (Overpass) API.
///
/// Only fields present in the source data are populated; everything else stays
/// `null` so the UI can simply hide what it does not have. Distance is the only
/// value the app computes, and it is derived from real coordinates.
class HealthcarePlace {
  /// Stable OSM identifier, e.g. `node/123456`.
  final String id;

  /// Display name. Falls back to the facility type when OSM has no name.
  final String name;

  final HealthcarePlaceType type;

  final double latitude;
  final double longitude;

  /// Human readable address assembled from the OSM `addr:*` tags.
  final String? address;

  final String? phone;
  final String? website;
  final String? openingHours;

  /// Data source (always OpenStreetMap for now).
  final String source;

  /// Straight-line distance from the user in meters; null until calculated.
  final double? distanceMeters;

  const HealthcarePlace({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.website,
    this.openingHours,
    this.source = 'OpenStreetMap',
    this.distanceMeters,
  });

  GeoPoint get location =>
      GeoPoint(latitude: latitude, longitude: longitude);

  /// Short distance label ("250 m", "800 m", "1.2 km"), or null if unknown.
  String? get distanceLabel {
    final d = distanceMeters;
    if (d == null) return null;
    return GeoUtils.formatDistance(d);
  }

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
  bool get hasWebsite => website != null && website!.trim().isNotEmpty;

  /// Returns a copy with [meters] stored as the distance from the user.
  HealthcarePlace withDistance(double meters) => HealthcarePlace(
        id: id,
        name: name,
        type: type,
        latitude: latitude,
        longitude: longitude,
        address: address,
        phone: phone,
        website: website,
        openingHours: openingHours,
        source: source,
        distanceMeters: meters,
      );

  /// Case-insensitive partial match on name, address and type.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final fields = <String?>[name, address, type.singular, type.plural];
    return fields.any((value) => (value ?? '').toLowerCase().contains(q));
  }

  /// Builds a place from a single Overpass API element.
  ///
  /// Returns null when the element is not a supported facility or has no
  /// usable coordinates, so unknown data is skipped rather than fabricated.
  static HealthcarePlace? fromOsmElement(Map<String, dynamic> element) {
    final tags = _asStringMap(element['tags']);
    final type = HealthcarePlaceType.fromOsmAmenity(tags['amenity']);
    if (type == null) return null;

    final coords = _coordinates(element);
    if (coords == null) return null;

    final name = _clean(tags['name']) ?? type.singular;

    return HealthcarePlace(
      id: '${element['type']}/${element['id']}',
      name: name,
      type: type,
      latitude: coords.$1,
      longitude: coords.$2,
      address: _buildAddress(tags),
      phone: _clean(tags['phone']) ?? _clean(tags['contact:phone']),
      website: _clean(tags['website']) ?? _clean(tags['contact:website']),
      openingHours: _clean(tags['opening_hours']),
    );
  }

  static (double, double)? _coordinates(Map<String, dynamic> element) {
    final lat = element['lat'];
    final lon = element['lon'];
    if (lat is num && lon is num) {
      return (lat.toDouble(), lon.toDouble());
    }
    // Ways and relations expose coordinates via the `center` field.
    final center = element['center'];
    if (center is Map) {
      final cLat = center['lat'];
      final cLon = center['lon'];
      if (cLat is num && cLon is num) {
        return (cLat.toDouble(), cLon.toDouble());
      }
    }
    return null;
  }

  static String? _buildAddress(Map<String, String> tags) {
    final full = _clean(tags['addr:full']);
    if (full != null) return full;

    final parts = <String>[];
    for (final key in const [
      'addr:housenumber',
      'addr:street',
      'addr:suburb',
      'addr:city',
      'addr:state',
      'addr:postcode',
    ]) {
      final value = _clean(tags[key]);
      if (value != null) parts.add(value);
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  static Map<String, String> _asStringMap(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        entry.key.toString(): entry.value.toString(),
    };
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is HealthcarePlace && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
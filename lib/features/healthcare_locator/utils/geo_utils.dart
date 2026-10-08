import 'dart:math' as math;

/// Geographic helpers for the healthcare locator feature.
abstract final class GeoUtils {
  static const double _earthRadiusMeters = 6371000;

  /// Great-circle distance between two coordinates in meters (haversine).
  static double distanceInMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Formats [meters] as a short distance label ("250 m", "1.2 km").
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
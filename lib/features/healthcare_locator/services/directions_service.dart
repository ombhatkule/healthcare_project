import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// A computed driving route between two points.
class RouteResult {
  /// Route length in meters.
  final double distanceMeters;

  /// Estimated travel time in seconds.
  final double durationSeconds;

  /// Ordered path of the route (used to draw the polyline on the map).
  final List<GeoPoint> polyline;

  const RouteResult({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polyline,
  });

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0 ? '$hours h' : '$hours h $remaining min';
  }
}

/// Raised when a route could not be calculated.
class DirectionsException implements Exception {
  final String message;
  const DirectionsException([this.message = 'Could not calculate a route.']);

  @override
  String toString() => 'DirectionsException: $message';
}

/// Contract for turn-by-turn routing between two coordinates.
abstract class DirectionsService {
  Future<RouteResult> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  });
}

/// [DirectionsService] backed by the public OSRM demo server.
///
/// Routing is a convenience only; callers must fall back to opening the
/// device's maps app when this throws.
class OsrmDirectionsService implements DirectionsService {
  OsrmDirectionsService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? defaultBaseUrl;

  static const String defaultBaseUrl = 'https://router.project-osrm.org';
  static const Duration _timeout = Duration(seconds: 15);

  /// Identifier sent with every request, as required by the public OSRM
  /// demo server's usage policy.
  static const String userAgent =
      'healthcare_app/1.0 (com.healthcareapp.healthcare_app)';

  static const Map<String, String> _headers = {
    'User-Agent': userAgent,
    'Accept': 'application/json',
  };

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<RouteResult> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    final coordinates = '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';
    final uri = Uri.parse(
      '$_baseUrl/route/v1/driving/$coordinates'
      '?overview=full&geometries=geojson',
    );

    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(_timeout);
    } on TimeoutException {
      throw const DirectionsException('The route request timed out.');
    } catch (_) {
      throw const DirectionsException();
    }

    if (response.statusCode != 200) {
      throw const DirectionsException();
    }

    final Object? decoded;
    try {
      decoded = json.decode(response.body);
    } catch (_) {
      throw const DirectionsException();
    }
    if (decoded is! Map || decoded['code'] != 'Ok') {
      throw const DirectionsException();
    }

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      throw const DirectionsException();
    }
    final route = routes.first;
    if (route is! Map) throw const DirectionsException();

    final distance = route['distance'];
    final duration = route['duration'];
    if (distance is! num || duration is! num) {
      throw const DirectionsException();
    }

    return RouteResult(
      distanceMeters: distance.toDouble(),
      durationSeconds: duration.toDouble(),
      polyline: _parsePolyline(route['geometry']),
    );
  }

  static List<GeoPoint> _parsePolyline(Object? geometry) {
    if (geometry is! Map) return const [];
    final coordinates = geometry['coordinates'];
    if (coordinates is! List) return const [];
    final points = <GeoPoint>[];
    for (final coordinate in coordinates) {
      if (coordinate is List && coordinate.length >= 2) {
        final lng = coordinate[0];
        final lat = coordinate[1];
        if (lat is num && lng is num) {
          points.add(
            GeoPoint(latitude: lat.toDouble(), longitude: lng.toDouble()),
          );
        }
      }
    }
    return points;
  }
}
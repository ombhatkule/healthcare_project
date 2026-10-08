import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Why a nearby-facility lookup failed.
///
/// This is deliberately more specific than a single "network error" so the UI
/// can tell the user whether their connection, the public Overpass service, or
/// the response itself was the problem.
enum HealthcareServiceFailure {
  /// The device could not reach the service (no connectivity, DNS, socket).
  network,

  /// The public Overpass service was reachable but could not serve the request
  /// (rate limiting, overload, maintenance, gateway errors).
  unavailable,

  /// The service answered with an unexpected status code.
  server,

  /// The response could not be parsed into facilities.
  parsing,
}

/// Raised by [HealthcarePlacesService] with a classified [failure] reason.
///
/// The underlying [cause] is preserved so it can be logged for diagnosis
/// without ever being shown to the user.
class HealthcarePlacesException implements Exception {
  const HealthcarePlacesException(
    this.failure, {
    this.message = '',
    this.statusCode,
    this.cause,
  });

  final HealthcareServiceFailure failure;
  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('HealthcarePlacesException(')
      ..write(failure.name);
    if (statusCode != null) buffer.write(', status: $statusCode');
    if (message.isNotEmpty) buffer.write(', $message');
    if (cause != null) buffer.write(', cause: $cause');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Contract for obtaining nearby hospitals and pharmacies.
abstract class HealthcarePlacesService {
  Future<List<HealthcarePlace>> fetchNearby({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  });
}

/// [HealthcarePlacesService] backed by the public OpenStreetMap Overpass API.
///
/// Public Overpass instances require a descriptive `User-Agent`; requests that
/// use the platform default (e.g. `Dart/3.7 (dart:io)`) are rejected with
/// HTTP 406 (overpass-api.de) or HTTP 429 ("supply a meaningful User-Agent").
/// A stable identifier is therefore always sent. Several mirrors are tried in
/// turn so a single overloaded instance does not take the feature down.
class OverpassHealthcarePlacesService implements HealthcarePlacesService {
  OverpassHealthcarePlacesService({
    http.Client? client,
    List<String> endpoints = defaultEndpoints,
  })  : _client = client ?? http.Client(),
        _endpoints = endpoints;

  /// Endpoints tried, in order, until one answers successfully.
  static const List<String> defaultEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  /// Identifier sent with every request, as required by the Overpass usage
  /// policy. Without it the public instances reject the request outright.
  static const String userAgent =
      'healthcare_app/1.0 (com.healthcareapp.healthcare_app)';

  static const Map<String, String> _headers = {
    'User-Agent': userAgent,
    'Accept': 'application/json',
  };

  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client;
  final List<String> _endpoints;

  @override
  Future<List<HealthcarePlace>> fetchNearby({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    final query = buildQuery(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );

    HealthcarePlacesException? lastError;
    for (final endpoint in _endpoints) {
      try {
        final response = await _client
            .post(
              Uri.parse(endpoint),
              headers: _headers,
              body: {'data': query},
            )
            .timeout(_timeout);
        if (response.statusCode != 200) {
          throw _failureForStatus(response.statusCode);
        }
        return parseResponse(response.body);
      } on TimeoutException catch (error) {
        lastError = HealthcarePlacesException(
          HealthcareServiceFailure.unavailable,
          message: 'The request to the facility service timed out.',
          cause: error,
        );
      } on HealthcarePlacesException catch (error) {
        lastError = error;
      } catch (error) {
        lastError = HealthcarePlacesException(
          HealthcareServiceFailure.network,
          message: 'Could not reach the facility service.',
          cause: error,
        );
      }
    }

    throw lastError ??
        const HealthcarePlacesException(
          HealthcareServiceFailure.network,
          message: 'Could not reach the facility service.',
        );
  }

  static HealthcarePlacesException _failureForStatus(int status) {
    const temporary = {406, 408, 429, 500, 502, 503, 504};
    return HealthcarePlacesException(
      temporary.contains(status)
          ? HealthcareServiceFailure.unavailable
          : HealthcareServiceFailure.server,
      statusCode: status,
      message: 'The facility service returned HTTP $status.',
    );
  }

  /// Builds the Overpass QL query for hospitals and pharmacies near a point.
  static String buildQuery({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) {
    final around = '(around:${radiusMeters.round()},$latitude,$longitude)';
    return '[out:json][timeout:25];\n'
        '(\n'
        '  node["amenity"="hospital"]$around;\n'
        '  way["amenity"="hospital"]$around;\n'
        '  relation["amenity"="hospital"]$around;\n'
        '  node["amenity"="pharmacy"]$around;\n'
        '  way["amenity"="pharmacy"]$around;\n'
        '  relation["amenity"="pharmacy"]$around;\n'
        ');\n'
        'out center tags;\n';
  }

  /// Parses an Overpass response body into [HealthcarePlace]s.
  ///
  /// Elements that are not supported facilities or have no usable coordinates
  /// are skipped rather than fabricated. Invalid or unexpected bodies raise a
  /// [HealthcareServiceFailure.parsing] error so the caller can distinguish a
  /// bad response from a connectivity problem.
  static List<HealthcarePlace> parseResponse(String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (error) {
      throw HealthcarePlacesException(
        HealthcareServiceFailure.parsing,
        message: 'The facility service returned an unreadable response.',
        cause: error,
      );
    }
    if (decoded is! Map) {
      throw const HealthcarePlacesException(
        HealthcareServiceFailure.parsing,
        message: 'The facility service returned an unexpected response.',
      );
    }

    final elements = decoded['elements'];
    if (elements is! List) return const [];

    final places = <HealthcarePlace>[];
    for (final element in elements) {
      if (element is! Map) continue;
      final place = HealthcarePlace.fromOsmElement(
        element.cast<String, dynamic>(),
      );
      if (place != null) places.add(place);
    }
    return places;
  }
}
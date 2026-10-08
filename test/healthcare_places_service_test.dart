import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/healthcare_locator/models/models.dart';
import 'package:healthcare_app/features/healthcare_locator/services/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OverpassHealthcarePlacesService.buildQuery', () {
    test('queries hospitals and pharmacies around the point', () {
      final query = OverpassHealthcarePlacesService.buildQuery(
        latitude: 12.34,
        longitude: 56.78,
        radiusMeters: 5000,
      );
      expect(query, contains('"amenity"="hospital"'));
      expect(query, contains('"amenity"="pharmacy"'));
      expect(query, contains('(around:5000,12.34,56.78)'));
    });
  });

  group('OverpassHealthcarePlacesService.parseResponse', () {
    test('maps supported elements and skips the rest', () {
      final body = jsonEncode({
        'elements': [
          {
            'type': 'node',
            'id': 1,
            'lat': 10.0,
            'lon': 20.0,
            'tags': {'amenity': 'hospital', 'name': 'A'},
          },
          {
            'type': 'way',
            'id': 2,
            'center': {'lat': 11.0, 'lon': 21.0},
            'tags': {'amenity': 'pharmacy'},
          },
          {
            'type': 'node',
            'id': 3,
            'lat': 12.0,
            'lon': 22.0,
            'tags': {'amenity': 'cafe'},
          },
          {'type': 'node', 'id': 4, 'tags': {'amenity': 'hospital'}},
        ],
      });

      final places = OverpassHealthcarePlacesService.parseResponse(body);
      expect(places, hasLength(2));
      expect(places[0].name, 'A');
      expect(places[1].name, 'Pharmacy');
    });

    test('throws a parsing error for invalid JSON', () {
      expect(
        () => OverpassHealthcarePlacesService.parseResponse('<html>'),
        throwsA(
          isA<HealthcarePlacesException>().having(
            (e) => e.failure,
            'failure',
            HealthcareServiceFailure.parsing,
          ),
        ),
      );
    });

    test('returns an empty list when elements is missing', () {
      expect(
        OverpassHealthcarePlacesService.parseResponse('{"version":0.6}'),
        isEmpty,
      );
    });
  });

  group('OverpassHealthcarePlacesService.fetchNearby', () {
    test('posts the query with a User-Agent and returns parsed places', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 7,
                'lat': 1.0,
                'lon': 2.0,
                'tags': {'amenity': 'hospital', 'name': 'Demo'},
              },
            ],
          }),
          200,
        );
      });

      final service = OverpassHealthcarePlacesService(
        client: client,
        endpoints: const ['https://example.test/api'],
      );

      final places = await service.fetchNearby(
        latitude: 1,
        longitude: 2,
        radiusMeters: 3000,
      );

      expect(places, hasLength(1));
      expect(captured.method, 'POST');
      expect(captured.body, contains('amenity'));
      expect(captured.body, contains('around%3A3000'));
      // Public Overpass instances reject requests without a meaningful
      // User-Agent (HTTP 406/429), so the header must always be present.
      expect(
        captured.headers['User-Agent'] ??
            captured.headers['user-agent'],
        OverpassHealthcarePlacesService.userAgent,
      );
    });

    test('classifies 429 rate-limiting as temporarily unavailable', () {
      final client = MockClient((_) async => http.Response('slow down', 429));
      final service = OverpassHealthcarePlacesService(
        client: client,
        endpoints: const ['https://example.test/api'],
      );

      expect(
        service.fetchNearby(latitude: 1, longitude: 2, radiusMeters: 5000),
        throwsA(
          isA<HealthcarePlacesException>()
              .having(
                (e) => e.failure,
                'failure',
                HealthcareServiceFailure.unavailable,
              )
              .having((e) => e.statusCode, 'statusCode', 429),
        ),
      );
    });

    test('classifies 406 (missing User-Agent) as temporarily unavailable', () {
      final client = MockClient((_) async => http.Response('nope', 406));
      final service = OverpassHealthcarePlacesService(
        client: client,
        endpoints: const ['https://example.test/api'],
      );

      expect(
        service.fetchNearby(latitude: 1, longitude: 2, radiusMeters: 5000),
        throwsA(
          isA<HealthcarePlacesException>().having(
            (e) => e.failure,
            'failure',
            HealthcareServiceFailure.unavailable,
          ),
        ),
      );
    });

    test('classifies an unexpected status as a server error', () {
      final client = MockClient((_) async => http.Response('nope', 400));
      final service = OverpassHealthcarePlacesService(
        client: client,
        endpoints: const ['https://example.test/api'],
      );

      expect(
        service.fetchNearby(latitude: 1, longitude: 2, radiusMeters: 5000),
        throwsA(
          isA<HealthcarePlacesException>().having(
            (e) => e.failure,
            'failure',
            HealthcareServiceFailure.server,
          ),
        ),
      );
    });

    test('classifies a connection failure as a network error', () {
      final client = MockClient((_) async {
        throw const SocketException('no route to host');
      });
      final service = OverpassHealthcarePlacesService(
        client: client,
        endpoints: const ['https://example.test/api'],
      );

      expect(
        service.fetchNearby(latitude: 1, longitude: 2, radiusMeters: 5000),
        throwsA(
          isA<HealthcarePlacesException>().having(
            (e) => e.failure,
            'failure',
            HealthcareServiceFailure.network,
          ),
        ),
      );
    });

    test('classifies a request timeout as temporarily unavailable', () {
      final client = MockClient((_) async {
        throw TimeoutException('too slow');
      });
      final service = OverpassHealthcarePlacesService(
        client: client,
        endpoints: const ['https://example.test/api'],
      );

      expect(
        service.fetchNearby(latitude: 1, longitude: 2, radiusMeters: 5000),
        throwsA(
          isA<HealthcarePlacesException>().having(
            (e) => e.failure,
            'failure',
            HealthcareServiceFailure.unavailable,
          ),
        ),
      );
    });

    test('falls back to the next endpoint after a failure', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (request.url.host == 'bad.test') {
          return http.Response('down', 503);
        }
        return http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 9,
                'lat': 1.0,
                'lon': 2.0,
                'tags': {'amenity': 'pharmacy', 'name': 'Backup'},
              },
            ],
          }),
          200,
        );
      });
      final service = OverpassHealthcarePlacesService(
        client: client,
        endpoints: const [
          'https://bad.test/api',
          'https://good.test/api',
        ],
      );

      final places = await service.fetchNearby(
        latitude: 1,
        longitude: 2,
        radiusMeters: 5000,
      );

      expect(calls, 2);
      expect(places.single.name, 'Backup');
    });
  });

  group('OsrmDirectionsService', () {
    test('parses distance, duration and polyline', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('/route/v1/driving/'));
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 1200.0,
                'duration': 360.0,
                'geometry': {
                  'coordinates': [
                    [75.8573, 30.9010],
                    [75.87, 30.91],
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final service = OsrmDirectionsService(
        client: client,
        baseUrl: 'https://example.test',
      );

      final route = await service.getRoute(
        origin: const GeoPoint(latitude: 30.9010, longitude: 75.8573),
        destination: const GeoPoint(latitude: 30.95, longitude: 75.90),
      );

      expect(route.distanceMeters, 1200);
      expect(route.durationSeconds, 360);
      expect(route.polyline, hasLength(2));
      expect(route.polyline.first.latitude, 30.9010);
    });

    test('throws DirectionsException on a non-Ok response', () {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'code': 'NoRoute'}), 200),
      );
      final service = OsrmDirectionsService(
        client: client,
        baseUrl: 'https://example.test',
      );

      expect(
        () => service.getRoute(
          origin: const GeoPoint(latitude: 0, longitude: 0),
          destination: const GeoPoint(latitude: 1, longitude: 1),
        ),
        throwsA(isA<DirectionsException>()),
      );
    });
  });
}
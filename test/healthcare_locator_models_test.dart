import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/healthcare_locator/models/models.dart';
import 'package:healthcare_app/features/healthcare_locator/utils/geo_utils.dart';

void main() {
  group('GeoUtils', () {
    test('distanceInMeters uses the haversine formula', () {
      final meters = GeoUtils.distanceInMeters(0, 0, 0, 1);
      expect(meters, closeTo(111194.9, 100));
    });

    test('formatDistance uses meters below 1 km', () {
      expect(GeoUtils.formatDistance(250), '250 m');
      expect(GeoUtils.formatDistance(800), '800 m');
    });

    test('formatDistance uses one decimal km at or above 1 km', () {
      expect(GeoUtils.formatDistance(1200), '1.2 km');
      expect(GeoUtils.formatDistance(4800), '4.8 km');
      expect(GeoUtils.formatDistance(1000), '1.0 km');
    });
  });

  group('HealthcarePlace.fromOsmElement', () {
    test('parses a node with full tags', () {
      final place = HealthcarePlace.fromOsmElement({
        'type': 'node',
        'id': 42,
        'lat': 30.9,
        'lon': 75.85,
        'tags': {
          'amenity': 'hospital',
          'name': 'City Hospital',
          'addr:housenumber': '12',
          'addr:street': 'Main Road',
          'addr:city': 'Ludhiana',
          'phone': '+91 12345',
          'website': 'https://city.example',
          'opening_hours': '24/7',
        },
      });

      expect(place, isNotNull);
      expect(place!.id, 'node/42');
      expect(place.name, 'City Hospital');
      expect(place.type, HealthcarePlaceType.hospital);
      expect(place.address, '12, Main Road, Ludhiana');
      expect(place.phone, '+91 12345');
      expect(place.website, 'https://city.example');
      expect(place.openingHours, '24/7');
      expect(place.source, 'OpenStreetMap');
    });

    test('parses a way via its center coordinates', () {
      final place = HealthcarePlace.fromOsmElement({
        'type': 'way',
        'id': 7,
        'center': {'lat': 12.5, 'lon': 77.5},
        'tags': {'amenity': 'pharmacy', 'name': 'MedPlus'},
      });

      expect(place, isNotNull);
      expect(place!.id, 'way/7');
      expect(place.type, HealthcarePlaceType.pharmacy);
      expect(place.latitude, 12.5);
      expect(place.longitude, 77.5);
    });

    test('falls back to the type label when unnamed', () {
      final place = HealthcarePlace.fromOsmElement({
        'type': 'node',
        'id': 1,
        'lat': 1,
        'lon': 1,
        'tags': {'amenity': 'pharmacy'},
      });
      expect(place!.name, 'Pharmacy');
    });

    test('returns null for unsupported amenities', () {
      final place = HealthcarePlace.fromOsmElement({
        'type': 'node',
        'id': 1,
        'lat': 1,
        'lon': 1,
        'tags': {'amenity': 'cafe'},
      });
      expect(place, isNull);
    });

    test('returns null when coordinates are missing', () {
      final place = HealthcarePlace.fromOsmElement({
        'type': 'node',
        'id': 1,
        'tags': {'amenity': 'hospital'},
      });
      expect(place, isNull);
    });
  });

  group('HealthcarePlace helpers', () {
    HealthcarePlace place({
      String name = 'Alpha Clinic',
      String? address,
      double? distance,
      HealthcarePlaceType type = HealthcarePlaceType.hospital,
    }) =>
        HealthcarePlace(
          id: 'node/1',
          name: name,
          type: type,
          latitude: 0,
          longitude: 0,
          address: address,
          distanceMeters: distance,
        );

    test('distanceLabel is null until a distance is set', () {
      expect(place().distanceLabel, isNull);
    });

    test('withDistance sets a formatted distance label', () {
      expect(place(distance: 250).distanceLabel, '250 m');
      expect(place(distance: 4800).distanceLabel, '4.8 km');
    });

    test('matchesQuery is case-insensitive and partial', () {
      final p = place(name: 'Sunrise Hospital', address: 'Main Road');
      expect(p.matchesQuery('sun'), isTrue);
      expect(p.matchesQuery('MAIN'), isTrue);
      expect(p.matchesQuery('clinic'), isFalse);
      expect(p.matchesQuery('   '), isTrue);
    });

    test('matchesQuery matches the type label', () {
      final p = place(type: HealthcarePlaceType.pharmacy);
      expect(p.matchesQuery('pharm'), isTrue);
    });

    test('hasPhone/hasWebsite reflect non-empty values', () {
      final p = HealthcarePlace(
        id: 'node/2',
        name: 'X',
        type: HealthcarePlaceType.hospital,
        latitude: 0,
        longitude: 0,
        phone: '',
        website: 'https://x.example',
      );
      expect(p.hasPhone, isFalse);
      expect(p.hasWebsite, isTrue);
    });
  });
}
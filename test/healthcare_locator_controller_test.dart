import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/constants/constants.dart';
import 'package:healthcare_app/features/healthcare_locator/models/models.dart';
import 'package:healthcare_app/features/healthcare_locator/presentation/providers/healthcare_locator_controller.dart';
import 'package:healthcare_app/features/healthcare_locator/services/services.dart';

import 'fake_healthcare_locator_services.dart';

void main() {
  const userPosition = GeoPoint(latitude: 30.9010, longitude: 75.8573);

  HealthcarePlace hospitalNear() => const HealthcarePlace(
        id: 'node/1',
        name: 'Alpha Hospital',
        type: HealthcarePlaceType.hospital,
        latitude: 30.9030,
        longitude: 75.8573,
      );

  HealthcarePlace pharmacyFar() => const HealthcarePlace(
        id: 'node/2',
        name: 'Zeta Pharmacy',
        type: HealthcarePlaceType.pharmacy,
        latitude: 30.9500,
        longitude: 75.8573,
        address: 'Main Bazaar',
        phone: '+91 90000',
        website: 'zeta.example',
      );

  HealthcareLocatorController build({
    LocationResult? location,
    List<HealthcarePlace> places = const [],
    Object? placesError,
    Object? routeError,
    RouteResult? route,
    FakeLinkLauncher? launcher,
  }) {
    return HealthcareLocatorController(
      locationService: FakeLocationService(
        result: location ?? const LocationResult.success(userPosition),
      ),
      placesService:
          FakeHealthcarePlacesService(places: places, error: placesError),
      directionsService: FakeDirectionsService(
        result: route,
        error: routeError,
      ),
      linkLauncher: launcher ?? FakeLinkLauncher(),
    );
  }

  group('load', () {
    test('fetches places with computed distances sorted nearest first', () async {
      final controller = build(places: [pharmacyFar(), hospitalNear()]);

      await controller.load();

      expect(controller.hasLocation, isTrue);
      expect(controller.places, hasLength(2));
      expect(controller.places.first.id, 'node/1');
      expect(controller.places.first.distanceMeters, closeTo(222, 15));
      expect(controller.places.last.id, 'node/2');
    });

    test('reports a disabled location service', () async {
      final controller = build(
        location: const LocationResult.failure(
          LocationFailureType.serviceDisabled,
        ),
      );

      await controller.load();

      expect(controller.hasLocationError, isTrue);
      expect(
        controller.locationErrorMessage,
        AppStrings.locationServiceDisabled,
      );
      expect(controller.places, isEmpty);
    });

    test('maps every permission/timeout failure to a message', () async {
      final expectations = {
        LocationFailureType.permissionDenied:
            AppStrings.locationPermissionDenied,
        LocationFailureType.permissionDeniedForever:
            AppStrings.locationPermissionDeniedForever,
        LocationFailureType.timeout: AppStrings.locationTimeout,
        LocationFailureType.unavailable: AppStrings.locationUnavailable,
      };

      for (final entry in expectations.entries) {
        final controller =
            build(location: LocationResult.failure(entry.key));
        await controller.load();
        expect(controller.locationErrorMessage, entry.value);
      }
    });

    test('surfaces a places error without crashing', () async {
      final controller = build(placesError: Exception('boom'));

      await controller.load();

      expect(controller.hasLocation, isTrue);
      expect(controller.hasPlacesError, isTrue);
      expect(controller.placesError, AppStrings.placesLoadFailed);
    });

    test('classifies facility service failures into messages', () async {
      final expectations = {
        HealthcareServiceFailure.network: AppStrings.placesNetworkError,
        HealthcareServiceFailure.unavailable:
            AppStrings.placesTemporarilyUnavailable,
        HealthcareServiceFailure.server: AppStrings.placesServiceError,
        HealthcareServiceFailure.parsing: AppStrings.placesServiceError,
      };

      for (final entry in expectations.entries) {
        final controller = build(
          placesError: HealthcarePlacesException(entry.key),
        );
        await controller.load();
        expect(controller.placesError, entry.value);
      }
    });
  });

  group('filtering and sorting', () {
    test('filters by search query', () async {
      final controller = build(places: [hospitalNear(), pharmacyFar()]);
      await controller.load();

      controller.updateQuery('zeta');

      expect(controller.places, hasLength(1));
      expect(controller.places.single.id, 'node/2');
    });

    test('filters by type', () async {
      final controller = build(places: [hospitalNear(), pharmacyFar()]);
      await controller.load();

      controller.selectType(HealthcarePlaceType.hospital);

      expect(controller.places, hasLength(1));
      expect(controller.places.single.type, HealthcarePlaceType.hospital);

      controller.selectType(null);
      expect(controller.places, hasLength(2));
    });

    test('sorts by name when requested', () async {
      final controller = build(places: [hospitalNear(), pharmacyFar()]);
      await controller.load();

      controller.setSort(HealthcareSort.name);

      expect(controller.places.first.name, 'Alpha Hospital');
      expect(controller.places.last.name, 'Zeta Pharmacy');
    });
  });

  test('expandSearchArea doubles the radius and refetches', () async {
    final service = FakeHealthcarePlacesService(places: [hospitalNear()]);
    final controller = HealthcareLocatorController(
      locationService:
          FakeLocationService(result: const LocationResult.success(userPosition)),
      placesService: service,
      directionsService: FakeDirectionsService(),
      linkLauncher: FakeLinkLauncher(),
    );

    await controller.load();
    expect(service.lastRadiusMeters, 5000);

    await controller.expandSearchArea();
    expect(service.lastRadiusMeters, 10000);
    expect(service.callCount, 2);
  });

  group('directions and actions', () {
    test('loadRoute stores a successful route', () async {
      const route = RouteResult(
        distanceMeters: 1000,
        durationSeconds: 60,
        polyline: [userPosition],
      );
      final controller = build(places: [hospitalNear()], route: route);
      await controller.load();

      final result = await controller.loadRoute(controller.places.first);

      expect(result, isNotNull);
      expect(controller.route, isNotNull);
      expect(controller.route!.distanceMeters, 1000);
    });

    test('loadRoute returns null on failure', () async {
      final controller = build(
        places: [hospitalNear()],
        routeError: Exception('no route'),
      );
      await controller.load();

      final result = await controller.loadRoute(controller.places.first);

      expect(result, isNull);
      expect(controller.route, isNull);
    });

    test('callPlace, openWebsite and openExternalDirections delegate', () async {
      final launcher = FakeLinkLauncher();
      final controller = build(places: [pharmacyFar()], launcher: launcher);
      await controller.load();
      final place = controller.places.single;

      await controller.callPlace(place);
      await controller.openWebsite(place);
      await controller.openExternalDirections(place);

      expect(launcher.lastPhone, '+91 90000');
      expect(launcher.lastUrl, 'https://zeta.example');
      expect(launcher.lastLatitude, place.latitude);
      expect(launcher.lastLongitude, place.longitude);
    });

    test('callPlace returns false when no phone number', () async {
      final launcher = FakeLinkLauncher();
      final controller = build(places: [hospitalNear()], launcher: launcher);
      await controller.load();

      final result = await controller.callPlace(controller.places.single);

      expect(result, isFalse);
      expect(launcher.lastPhone, isNull);
    });
  });
}
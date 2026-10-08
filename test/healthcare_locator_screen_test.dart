import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/constants/constants.dart';
import 'package:healthcare_app/features/healthcare_locator/models/models.dart';
import 'package:healthcare_app/features/healthcare_locator/presentation/screens/healthcare_locator_screen.dart';
import 'package:healthcare_app/features/healthcare_locator/services/services.dart';
import 'package:provider/provider.dart';

import 'fake_healthcare_locator_services.dart';

void main() {
  const userPosition = GeoPoint(latitude: 30.9010, longitude: 75.8573);

  const hospital = HealthcarePlace(
    id: 'node/1',
    name: 'Alpha Hospital',
    type: HealthcarePlaceType.hospital,
    latitude: 30.9030,
    longitude: 75.8573,
  );

  const pharmacy = HealthcarePlace(
    id: 'node/2',
    name: 'Zeta Pharmacy',
    type: HealthcarePlaceType.pharmacy,
    latitude: 30.9500,
    longitude: 75.8573,
    phone: '+91 90000',
  );

  Widget app({
    LocationResult? location,
    List<HealthcarePlace> places = const [],
    Object? placesError,
  }) {
    return MultiProvider(
      providers: [
        Provider<LocationService>.value(
          value: FakeLocationService(
            result: location ?? const LocationResult.success(userPosition),
          ),
        ),
        Provider<HealthcarePlacesService>.value(
          value: FakeHealthcarePlacesService(
            places: places,
            error: placesError,
          ),
        ),
        Provider<DirectionsService>.value(value: FakeDirectionsService()),
        Provider<LinkLauncher>.value(value: FakeLinkLauncher()),
      ],
      child: const MaterialApp(home: HealthcareLocatorScreen()),
    );
  }

  testWidgets('renders nearby facilities after location succeeds',
      (tester) async {
    await tester.pumpWidget(app(places: [hospital, pharmacy]));
    await tester.pumpAndSettle();

    expect(find.text('Alpha Hospital'), findsOneWidget);
    expect(find.text('Zeta Pharmacy'), findsOneWidget);
    expect(find.text(AppStrings.healthcareSourceNote), findsOneWidget);
  });

  testWidgets('search filters the visible facilities', (tester) async {
    await tester.pumpWidget(app(places: [hospital, pharmacy]));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zeta');
    await tester.pumpAndSettle();

    expect(find.text('Zeta Pharmacy'), findsOneWidget);
    expect(find.text('Alpha Hospital'), findsNothing);
  });

  testWidgets('type selector filters to hospitals', (tester) async {
    await tester.pumpWidget(app(places: [hospital, pharmacy]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hospitals'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha Hospital'), findsOneWidget);
    expect(find.text('Zeta Pharmacy'), findsNothing);
  });

  testWidgets('shows a location error with a retry action', (tester) async {
    await tester.pumpWidget(
      app(
        location: const LocationResult.failure(
          LocationFailureType.serviceDisabled,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.locationServiceDisabled), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  testWidgets('shows an empty state when nothing is found', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noResultsTitle), findsOneWidget);
    expect(find.text(AppStrings.tryAgain), findsOneWidget);
    expect(find.text(AppStrings.searchLargerArea), findsOneWidget);
  });

  testWidgets('shows an error state when facilities fail to load',
      (tester) async {
    await tester.pumpWidget(app(placesError: Exception('boom')));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.placesLoadFailed), findsOneWidget);
  });
}
import 'package:healthcare_app/features/healthcare_locator/models/models.dart';
import 'package:healthcare_app/features/healthcare_locator/services/services.dart';

/// Configurable fake [LocationService] for widget and controller tests.
class FakeLocationService implements LocationService {
  FakeLocationService({this.result});

  LocationResult? result;
  int callCount = 0;

  @override
  Future<LocationResult> getCurrentPosition() async {
    callCount++;
    return result ??
        const LocationResult.failure(LocationFailureType.unavailable);
  }
}

/// In-memory [HealthcarePlacesService] for tests.
class FakeHealthcarePlacesService implements HealthcarePlacesService {
  FakeHealthcarePlacesService({this.places = const [], this.error});

  List<HealthcarePlace> places;
  Object? error;
  int callCount = 0;
  double? lastLatitude;
  double? lastLongitude;
  double? lastRadiusMeters;

  @override
  Future<List<HealthcarePlace>> fetchNearby({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    callCount++;
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastRadiusMeters = radiusMeters;
    final failure = error;
    if (failure != null) throw failure;
    return places;
  }
}

/// Configurable [DirectionsService] for tests.
class FakeDirectionsService implements DirectionsService {
  FakeDirectionsService({this.result, this.error});

  RouteResult? result;
  Object? error;
  int callCount = 0;

  @override
  Future<RouteResult> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    callCount++;
    final failure = error;
    if (failure != null) throw failure;
    return result ??
        const RouteResult(
          distanceMeters: 0,
          durationSeconds: 0,
          polyline: [],
        );
  }
}

/// Records what the app tried to launch without touching platform channels.
class FakeLinkLauncher implements LinkLauncher {
  FakeLinkLauncher({this.result = true});

  bool result;
  String? lastUrl;
  String? lastPhone;
  double? lastLatitude;
  double? lastLongitude;

  @override
  Future<bool> openUrl(String url) async {
    lastUrl = url;
    return result;
  }

  @override
  Future<bool> callPhone(String phone) async {
    lastPhone = phone;
    return result;
  }

  @override
  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    lastLatitude = latitude;
    lastLongitude = longitude;
    return result;
  }
}
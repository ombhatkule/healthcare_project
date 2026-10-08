import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/models.dart';

/// Why a location lookup could not be completed.
enum LocationFailureType {
  /// The device location/GPS service is turned off.
  serviceDisabled,

  /// The user denied the permission request.
  permissionDenied,

  /// The user permanently denied permission; must be changed in settings.
  permissionDeniedForever,

  /// The fix could not be obtained in time.
  timeout,

  /// Any other platform failure.
  unavailable,
}

/// Outcome of a location lookup: either a [position] or a [failure].
class LocationResult {
  final GeoPoint? position;
  final LocationFailureType? failure;

  const LocationResult.success(GeoPoint this.position) : failure = null;
  const LocationResult.failure(LocationFailureType this.failure)
      : position = null;

  bool get isSuccess => position != null;
}

/// Contract for obtaining the device's current position.
abstract class LocationService {
  Future<LocationResult> getCurrentPosition();
}

/// [LocationService] backed by the `geolocator` plugin.
///
/// Permission is only requested here, at the moment the user opens the nearby
/// facilities feature, and never in the background. The plugin is given a time
/// limit so a device that cannot get a fix fails fast instead of hanging.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  static const Duration _timeLimit = Duration(seconds: 15);

  @override
  Future<LocationResult> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.failure(
          LocationFailureType.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
          LocationFailureType.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationResult.failure(
          LocationFailureType.permissionDenied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeLimit,
        ),
      );

      return LocationResult.success(
        GeoPoint(latitude: position.latitude, longitude: position.longitude),
      );
    } on TimeoutException {
      return const LocationResult.failure(LocationFailureType.timeout);
    } catch (_) {
      return const LocationResult.failure(LocationFailureType.unavailable);
    }
  }
}
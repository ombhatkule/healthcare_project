import 'package:flutter/foundation.dart';

import '../../../../core/constants/constants.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/geo_utils.dart';

/// Order in which nearby facilities are listed.
enum HealthcareSort {
  /// Closest to the user first (default).
  nearest,

  /// Alphabetical by name.
  name,
}

/// State management for the Hospital / Pharmacy Locator (Phase 16).
///
/// Owns the user's location, the facilities fetched around it, the search text
/// and the active filters. Facilities are fetched once per location and then
/// filtered/sorted in memory, so typing in the search box never triggers a new
/// network request.
class HealthcareLocatorController extends ChangeNotifier {
  HealthcareLocatorController({
    required LocationService locationService,
    required HealthcarePlacesService placesService,
    required DirectionsService directionsService,
    required LinkLauncher linkLauncher,
    HealthcarePlaceType? initialType,
    double radiusMeters = 5000,
  })  : _locationService = locationService,
        _placesService = placesService,
        _directionsService = directionsService,
        _linkLauncher = linkLauncher,
        _selectedType = initialType,
        _radiusMeters = radiusMeters;

  final LocationService _locationService;
  final HealthcarePlacesService _placesService;
  final DirectionsService _directionsService;
  final LinkLauncher _linkLauncher;

  /// Search radius in meters.
  double _radiusMeters;

  double get radiusMeters => _radiusMeters;

  HealthcarePlaceType? _selectedType;
  HealthcareSort _sort = HealthcareSort.nearest;
  String _query = '';

  GeoPoint? _userLocation;
  List<HealthcarePlace> _allPlaces = const [];

  bool _isLoadingLocation = false;
  bool _isLoadingPlaces = false;
  LocationFailureType? _locationFailure;
  String? _placesError;

  bool _isLoadingRoute = false;
  RouteResult? _route;

  // -------------------------------------------------------------------------
  // Read-only state
  // -------------------------------------------------------------------------

  HealthcarePlaceType? get selectedType => _selectedType;
  HealthcareSort get sort => _sort;
  String get query => _query;

  GeoPoint? get userLocation => _userLocation;
  bool get hasLocation => _userLocation != null;

  bool get isLoadingLocation => _isLoadingLocation;
  bool get isLoadingPlaces => _isLoadingPlaces;
  bool get isLoading => _isLoadingLocation || _isLoadingPlaces;

  LocationFailureType? get locationFailure => _locationFailure;
  bool get hasLocationError => _locationFailure != null;

  String? get placesError => _placesError;
  bool get hasPlacesError => _placesError != null;

  bool get isLoadingRoute => _isLoadingRoute;
  RouteResult? get route => _route;

  /// All fetched facilities, filtered by type and query and sorted.
  List<HealthcarePlace> get places {
    final filtered = _allPlaces.where((place) {
      if (_selectedType != null && place.type != _selectedType) return false;
      return place.matchesQuery(_query);
    }).toList(growable: false);

    final sorted = List<HealthcarePlace>.of(filtered);
    switch (_sort) {
      case HealthcareSort.nearest:
        sorted.sort((a, b) {
          final da = a.distanceMeters ?? double.infinity;
          final db = b.distanceMeters ?? double.infinity;
          return da.compareTo(db);
        });
      case HealthcareSort.name:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
    return List.unmodifiable(sorted);
  }

  bool get hasPlaces => _allPlaces.isNotEmpty;

  /// Human-readable message for the current location failure.
  String get locationErrorMessage {
    switch (_locationFailure) {
      case LocationFailureType.serviceDisabled:
        return AppStrings.locationServiceDisabled;
      case LocationFailureType.permissionDenied:
        return AppStrings.locationPermissionDenied;
      case LocationFailureType.permissionDeniedForever:
        return AppStrings.locationPermissionDeniedForever;
      case LocationFailureType.timeout:
        return AppStrings.locationTimeout;
      case LocationFailureType.unavailable:
      case null:
        return AppStrings.locationUnavailable;
    }
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  /// Requests location (once) and then loads nearby facilities.
  Future<void> load() async {
    if (_isLoadingLocation) return;

    _isLoadingLocation = true;
    _locationFailure = null;
    _placesError = null;
    _route = null;
    notifyListeners();

    final result = await _locationService.getCurrentPosition();
    _isLoadingLocation = false;

    if (!result.isSuccess) {
      _allPlaces = const [];
      _locationFailure = result.failure ?? LocationFailureType.unavailable;
      notifyListeners();
      return;
    }

    _userLocation = result.position;
    notifyListeners();
    await _fetchPlaces();
  }

  /// Re-runs the whole flow (used by retry buttons).
  Future<void> retry() => load();

  /// Widens the search radius and fetches again (used by the empty state).
  Future<void> expandSearchArea() async {
    _radiusMeters = (_radiusMeters * 2).clamp(1000, 50000);
    await _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    final location = _userLocation;
    if (location == null) return;

    _isLoadingPlaces = true;
    _placesError = null;
    notifyListeners();

    try {
      final fetched = await _placesService.fetchNearby(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusMeters: _radiusMeters,
      );
      _allPlaces = fetched.map((place) {
        final meters = GeoUtils.distanceInMeters(
          location.latitude,
          location.longitude,
          place.latitude,
          place.longitude,
        );
        return place.withDistance(meters);
      }).toList(growable: false);
    } on HealthcarePlacesException catch (error) {
      debugPrint('Healthcare locator: facility lookup failed '
          '(${error.failure.name}, status: ${error.statusCode}): ${error.cause ?? error.message}');
      _placesError = _messageForFailure(error.failure);
    } catch (error) {
      debugPrint('Healthcare locator: unexpected facility error: $error');
      _placesError = AppStrings.placesLoadFailed;
    } finally {
      _isLoadingPlaces = false;
      notifyListeners();
    }
  }

  /// Maps a classified service failure to a user-facing message.
  String _messageForFailure(HealthcareServiceFailure failure) {
    switch (failure) {
      case HealthcareServiceFailure.network:
        return AppStrings.placesNetworkError;
      case HealthcareServiceFailure.unavailable:
        return AppStrings.placesTemporarilyUnavailable;
      case HealthcareServiceFailure.server:
      case HealthcareServiceFailure.parsing:
        return AppStrings.placesServiceError;
    }
  }

  void selectType(HealthcarePlaceType? type) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
  }

  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void setSort(HealthcareSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  /// Loads a driving route to [place]. Returns null when routing is
  /// unavailable, in which case the caller falls back to an external maps app.
  Future<RouteResult?> loadRoute(HealthcarePlace place) async {
    final origin = _userLocation;
    if (origin == null) return null;

    _isLoadingRoute = true;
    _route = null;
    notifyListeners();

    try {
      final result = await _directionsService.getRoute(
        origin: origin,
        destination: place.location,
      );
      _route = result;
      return result;
    } catch (_) {
      _route = null;
      return null;
    } finally {
      _isLoadingRoute = false;
      notifyListeners();
    }
  }

  /// Opens the device's maps app with directions to [place].
  Future<bool> openExternalDirections(HealthcarePlace place) {
    return _linkLauncher.openDirections(
      latitude: place.latitude,
      longitude: place.longitude,
      label: place.name,
    );
  }

  /// Opens the platform dialer for [place] when it has a phone number.
  Future<bool> callPlace(HealthcarePlace place) {
    final phone = place.phone;
    if (phone == null || phone.trim().isEmpty) {
      return Future.value(false);
    }
    return _linkLauncher.callPhone(phone);
  }

  /// Opens [place]'s website in an external browser when it has one.
  Future<bool> openWebsite(HealthcarePlace place) {
    final website = place.website;
    if (website == null || website.trim().isEmpty) {
      return Future.value(false);
    }
    final normalized =
        website.startsWith('http') ? website : 'https://$website';
    return _linkLauncher.openUrl(normalized);
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../models/models.dart';

/// OpenStreetMap-based map showing the user, nearby facilities and (optionally)
/// a route polyline to the selected facility.
class HealthcareLocatorMap extends StatelessWidget {
  final GeoPoint? userLocation;
  final List<HealthcarePlace> places;
  final HealthcarePlace? selectedPlace;
  final List<GeoPoint> route;
  final ValueChanged<HealthcarePlace>? onPlaceTap;
  final double zoom;

  const HealthcareLocatorMap({
    super.key,
    this.userLocation,
    this.places = const [],
    this.selectedPlace,
    this.route = const [],
    this.onPlaceTap,
    this.zoom = 14,
  });

  static const String _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _userAgent = 'com.healthcareapp.healthcare_app';

  LatLng? get _center {
    if (selectedPlace != null) {
      return LatLng(selectedPlace!.latitude, selectedPlace!.longitude);
    }
    if (userLocation != null) {
      return LatLng(userLocation!.latitude, userLocation!.longitude);
    }
    if (places.isNotEmpty) {
      return LatLng(places.first.latitude, places.first.longitude);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final center = _center;
    if (center == null) {
      return const EmptyStateWidget(
        icon: Icons.map_outlined,
        title: 'Map unavailable',
        subtitle: 'Your location is needed to show the map.',
      );
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: zoom),
          children: [
            TileLayer(urlTemplate: _tileUrl, userAgentPackageName: _userAgent),
            if (route.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route
                        .map((point) => LatLng(point.latitude, point.longitude))
                        .toList(growable: false),
                    strokeWidth: 4,
                    color: AppColors.primary,
                  ),
                ],
              ),
            if (userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      userLocation!.latitude,
                      userLocation!.longitude,
                    ),
                    width: 32,
                    height: 32,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.info,
                      size: 24,
                    ),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final place in places)
                  Marker(
                    point: LatLng(place.latitude, place.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: onPlaceTap == null
                          ? null
                          : () => onPlaceTap!(place),
                      child: Icon(
                        place.type.icon,
                        color: place.type == HealthcarePlaceType.hospital
                            ? AppColors.error
                            : AppColors.accent,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.white70,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: const Text(
              AppStrings.osmAttribution,
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
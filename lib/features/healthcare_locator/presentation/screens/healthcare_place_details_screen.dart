import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../providers/healthcare_locator_controller.dart';
import '../widgets/healthcare_locator_map.dart';
import '../widgets/healthcare_source_note.dart';

/// Full details for a single hospital or pharmacy, with directions, call and
/// website actions.
class HealthcarePlaceDetailsScreen extends StatelessWidget {
  final HealthcarePlace place;

  const HealthcarePlaceDetailsScreen({super.key, required this.place});

  Future<void> _openDirections(BuildContext context) async {
    final controller = context.read<HealthcareLocatorController>();
    final route = await controller.loadRoute(place);
    if (!context.mounted) return;

    if (route == null) {
      AppUtils.showSnackBar(context, AppStrings.directionsLoadFailed);
      final opened = await controller.openExternalDirections(place);
      if (context.mounted && !opened) {
        AppUtils.showSnackBar(
          context,
          AppStrings.actionNotAvailable,
          isError: true,
        );
      }
    }
  }

  Future<void> _call(BuildContext context) async {
    final controller = context.read<HealthcareLocatorController>();
    final opened = await controller.callPlace(place);
    if (!context.mounted) return;
    AppUtils.showSnackBar(
      context,
      opened ? AppStrings.callingNumber : AppStrings.actionNotAvailable,
      isError: !opened,
    );
  }

  Future<void> _openWebsite(BuildContext context) async {
    final controller = context.read<HealthcareLocatorController>();
    final opened = await controller.openWebsite(place);
    if (!context.mounted) return;
    AppUtils.showSnackBar(
      context,
      opened ? AppStrings.openingWebsite : AppStrings.actionNotAvailable,
      isError: !opened,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HealthcareLocatorController>();
    final route = controller.route;
    final distance = place.distanceLabel;

    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      body: ListView(
        children: [
          SizedBox(
            height: 220,
            child: HealthcareLocatorMap(
              userLocation: controller.userLocation,
              places: [place],
              selectedPlace: place,
              route: route?.polyline ?? const [],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      avatar: Icon(place.type.icon, size: AppSizes.iconSm),
                      label: Text(place.type.singular),
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                    const Spacer(),
                    if (distance != null)
                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSm),
                if (place.address != null)
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: AppStrings.addressLabel,
                    value: place.address!,
                  ),
                if (place.phone != null)
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: AppStrings.phoneLabel,
                    value: place.phone!,
                  ),
                if (place.openingHours != null)
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: AppStrings.openingHoursLabel,
                    value: place.openingHours!,
                  ),
                if (place.website != null)
                  _DetailRow(
                    icon: Icons.language_outlined,
                    label: AppStrings.websiteLabel,
                    value: place.website!,
                  ),
                _DetailRow(
                  icon: Icons.source_outlined,
                  label: AppStrings.sourceLabel,
                  value: place.source,
                ),
                const SizedBox(height: AppSizes.paddingMd),
                if (route != null) _RouteCard(route: route),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.isLoadingRoute
                        ? null
                        : () => _openDirections(context),
                    icon: controller.isLoadingRoute
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.directions_outlined),
                    label: const Text(AppStrings.getDirections),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSm),
                Row(
                  children: [
                    if (place.hasPhone)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _call(context),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text(AppStrings.callAction),
                        ),
                      ),
                    if (place.hasPhone && place.hasWebsite)
                      const SizedBox(width: AppSizes.paddingSm),
                    if (place.hasWebsite)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openWebsite(context),
                          icon: const Icon(Icons.language_outlined),
                          label: const Text(AppStrings.openWebsite),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const HealthcareSourceNote(),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteResult route;

  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RouteStat(
              label: AppStrings.routeDistanceLabel,
              value: route.distanceLabel,
            ),
          ),
          Expanded(
            child: _RouteStat(
              label: AppStrings.routeDurationLabel,
              value: route.durationLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStat extends StatelessWidget {
  final String label;
  final String value;

  const _RouteStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconMd, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
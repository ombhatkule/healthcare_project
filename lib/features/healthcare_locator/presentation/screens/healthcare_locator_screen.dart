import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../providers/healthcare_locator_controller.dart';
import '../widgets/healthcare_locator_map.dart';
import '../widgets/healthcare_place_card.dart';
import '../widgets/healthcare_source_note.dart';
import 'healthcare_place_details_screen.dart';

/// Hospital / Pharmacy Locator (Phase 16).
///
/// Finds nearby hospitals and pharmacies via OpenStreetMap, lets the user
/// search/filter them, and offers directions and calling.
class HealthcareLocatorScreen extends StatelessWidget {
  /// Facility type selected when the screen opens; null shows everything.
  final HealthcarePlaceType? initialType;

  const HealthcareLocatorScreen({super.key, this.initialType});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HealthcareLocatorController>(
      create: (ctx) => HealthcareLocatorController(
        locationService: ctx.read<LocationService>(),
        placesService: ctx.read<HealthcarePlacesService>(),
        directionsService: ctx.read<DirectionsService>(),
        linkLauncher: ctx.read<LinkLauncher>(),
        initialType: initialType,
      )..load(),
      child: const _HealthcareLocatorView(),
    );
  }
}

class _HealthcareLocatorView extends StatefulWidget {
  const _HealthcareLocatorView();

  @override
  State<_HealthcareLocatorView> createState() => _HealthcareLocatorViewState();
}

class _HealthcareLocatorViewState extends State<_HealthcareLocatorView> {
  final TextEditingController _searchController = TextEditingController();
  bool _showMap = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetails(HealthcareLocatorController controller, HealthcarePlace place) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<HealthcareLocatorController>.value(
          value: controller,
          child: HealthcarePlaceDetailsScreen(place: place),
        ),
      ),
    );
  }

  Future<void> _quickDirections(
    HealthcareLocatorController controller,
    HealthcarePlace place,
  ) async {
    AppUtils.showSnackBar(context, AppStrings.openingMaps);
    final opened = await controller.openExternalDirections(place);
    if (!mounted) return;
    if (!opened) {
      AppUtils.showSnackBar(
        context,
        AppStrings.actionNotAvailable,
        isError: true,
      );
    }
  }

  Future<void> _quickCall(
    HealthcareLocatorController controller,
    HealthcarePlace place,
  ) async {
    final opened = await controller.callPlace(place);
    if (!mounted) return;
    AppUtils.showSnackBar(
      context,
      opened ? AppStrings.callingNumber : AppStrings.actionNotAvailable,
      isError: !opened,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HealthcareLocatorController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.healthcareLocatorTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.tryAgain,
            onPressed: controller.retry,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: _showMap
                ? AppStrings.listViewLabel
                : AppStrings.mapViewLabel,
            onPressed: () => setState(() => _showMap = !_showMap),
            icon: Icon(_showMap ? Icons.view_list_outlined : Icons.map_outlined),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(controller)),
    );
  }

  Widget _buildBody(HealthcareLocatorController controller) {
    if (controller.isLoadingLocation && !controller.hasLocation) {
      return const LoadingWidget(message: AppStrings.gettingLocation);
    }
    if (controller.hasLocationError) {
      return ErrorStateWidget(
        message: controller.locationErrorMessage,
        onRetry: controller.retry,
      );
    }

    return Column(
      children: [
        _buildFilters(controller),
        Expanded(child: _buildResults(controller)),
        const HealthcareSourceNote(),
      ],
    );
  }

  Widget _buildFilters(HealthcareLocatorController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMd,
        AppSizes.paddingSm,
        AppSizes.paddingMd,
        AppSizes.paddingSm,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: controller.updateQuery,
            decoration: AppDecorations.inputDecoration(
              labelText: '',
              hintText: AppStrings.searchHealthcareHint,
              prefixIcon: Icons.search,
              suffixIcon: controller.query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: AppStrings.filterAll,
                      onPressed: () {
                        _searchController.clear();
                        controller.updateQuery('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _typeChip(controller, null, AppStrings.filterAll),
                      const SizedBox(width: AppSizes.paddingXs),
                      _typeChip(
                        controller,
                        HealthcarePlaceType.hospital,
                        HealthcarePlaceType.hospital.plural,
                      ),
                      const SizedBox(width: AppSizes.paddingXs),
                      _typeChip(
                        controller,
                        HealthcarePlaceType.pharmacy,
                        HealthcarePlaceType.pharmacy.plural,
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<HealthcareSort>(
                tooltip: AppStrings.sortNearest,
                initialValue: controller.sort,
                onSelected: controller.setSort,
                icon: const Icon(Icons.sort),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: HealthcareSort.nearest,
                    child: Text(AppStrings.sortNearest),
                  ),
                  PopupMenuItem(
                    value: HealthcareSort.name,
                    child: Text(AppStrings.sortByName),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip(
    HealthcareLocatorController controller,
    HealthcarePlaceType? type,
    String label,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: controller.selectedType == type,
      onSelected: (_) => controller.selectType(type),
    );
  }

  Widget _buildResults(HealthcareLocatorController controller) {
    if (controller.isLoadingPlaces) {
      return const LoadingWidget(message: AppStrings.loadingNearbyPlaces);
    }
    if (controller.hasPlacesError) {
      return ErrorStateWidget(
        message: AppStrings.placesLoadFailed,
        onRetry: controller.retry,
      );
    }

    final places = controller.places;
    if (places.isEmpty) {
      return _EmptyResults(controller: controller);
    }

    if (_showMap) {
      return HealthcareLocatorMap(
        userLocation: controller.userLocation,
        places: places,
        onPlaceTap: (place) => _openDetails(controller, place),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return HealthcarePlaceCard(
          place: place,
          onViewDetails: () => _openDetails(controller, place),
          onDirections: () => _quickDirections(controller, place),
          onCall: place.hasPhone
              ? () => _quickCall(controller, place)
              : null,
        );
      },
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final HealthcareLocatorController controller;

  const _EmptyResults({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyStateWidget(
              icon: Icons.search_off_outlined,
              title: AppStrings.noResultsTitle,
              subtitle: AppStrings.noResultsMessage,
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Wrap(
              spacing: AppSizes.paddingSm,
              runSpacing: AppSizes.paddingSm,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: controller.retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.tryAgain),
                ),
                OutlinedButton.icon(
                  onPressed: controller.expandSearchArea,
                  icon: const Icon(Icons.zoom_out_map),
                  label: const Text(AppStrings.searchLargerArea),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
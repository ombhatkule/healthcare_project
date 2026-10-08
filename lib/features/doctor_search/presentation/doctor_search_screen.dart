import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../doctor_recommendation/models/doctor.dart';
import '../../doctor_recommendation/models/navigation_args.dart';
import '../../doctor_recommendation/presentation/widgets/doctor_card.dart';
import '../../doctor_recommendation/services/doctor_recommendation_service.dart';
import 'providers/doctor_search_controller.dart';

/// "Find a Doctor" â€” search and filter the doctor catalog.
///
/// Supports full-text search (name/specialty/hospital/location) combined
/// with specialty, location and rating filters plus result sorting. Results
/// reuse the [DoctorCard] and open the shared Doctor Details screen. A
/// shortcut keeps access to the recommended-doctors flow.
class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  static const List<double> _ratingOptions = [0, 4.0, 4.5, 4.8];

  final TextEditingController _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorSearchController>().initialize();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DoctorSearchController>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.doctorSearchTitle)),
      body: SafeArea(child: _buildBody(controller)),
    );
  }

  Widget _buildBody(DoctorSearchController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingMd,
            AppSizes.paddingMd,
            AppSizes.paddingMd,
            0,
          ),
          child: _buildSearchField(controller),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingMd,
            AppSizes.paddingSm,
            AppSizes.paddingMd,
            0,
          ),
          child: _buildFilters(controller),
        ),
        if (controller.hasActiveFilters)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingMd,
                0,
                AppSizes.paddingMd,
                0,
              ),
              child: TextButton.icon(
                onPressed: controller.clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined,
                    size: AppSizes.iconSm),
                label: const Text(AppStrings.clearFilters),
              ),
            ),
          ),
        const SizedBox(height: AppSizes.paddingXs),
        Expanded(child: _buildResults(controller)),
      ],
    );
  }

  Widget _buildSearchField(DoctorSearchController controller) {
    return TextField(
      controller: _queryController,
      textInputAction: TextInputAction.search,
      onChanged: controller.updateQuery,
      decoration: AppDecorations.inputDecoration(
        labelText: AppStrings.search,
        hintText: AppStrings.searchDoctorsHint,
        prefixIcon: Icons.search,
        suffixIcon: controller.query.trim().isEmpty
            ? null
            : IconButton(
                tooltip: AppStrings.clear,
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _queryController.clear();
                  controller.updateQuery('');
                },
              ),
      ),
    );
  }

  Widget _buildFilters(DoctorSearchController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _specialtyDropdown(controller),
            ),
            const SizedBox(width: AppSizes.paddingMd),
            Expanded(
              child: _locationDropdown(controller),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingSm),
        Row(
          children: [
            Expanded(
              child: _ratingDropdown(controller),
            ),
            const SizedBox(width: AppSizes.paddingMd),
            Expanded(
              child: _sortDropdown(controller),
            ),
          ],
        ),
      ],
    );
  }

  Widget _specialtyDropdown(DoctorSearchController controller) {
    return DropdownButtonFormField<String>(
      value: controller.selectedSpecialty.isEmpty
          ? null
          : controller.selectedSpecialty,
      isExpanded: true,
      decoration: AppDecorations.inputDecoration(
        labelText: AppStrings.specialtyLabel,
        prefixIcon: Icons.medical_services_outlined,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text(AppStrings.allSpecialties),
        ),
        for (final specialty in controller.specialties)
          DropdownMenuItem<String>(
            value: specialty,
            child: Text(
              specialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) => controller.setSpecialty(value ?? ''),
    );
  }

  Widget _locationDropdown(DoctorSearchController controller) {
    return DropdownButtonFormField<String>(
      value: controller.selectedLocation.isEmpty
          ? null
          : controller.selectedLocation,
      isExpanded: true,
      decoration: AppDecorations.inputDecoration(
        labelText: AppStrings.locationLabel,
        prefixIcon: Icons.location_on_outlined,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text(AppStrings.allLocations),
        ),
        for (final location in controller.locations)
          DropdownMenuItem<String>(
            value: location,
            child: Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) => controller.setLocation(value ?? ''),
    );
  }

  Widget _ratingDropdown(DoctorSearchController controller) {
    return DropdownButtonFormField<double>(
      value: controller.minRating == 0 ? null : controller.minRating,
      isExpanded: true,
      decoration: AppDecorations.inputDecoration(
        labelText: AppStrings.ratingLabel,
        prefixIcon: Icons.star_outline_rounded,
      ),
      items: [
        const DropdownMenuItem<double>(
          value: null,
          child: Text(AppStrings.anyRating),
        ),
        for (final rating in _ratingOptions)
          if (rating > 0)
            DropdownMenuItem<double>(
              value: rating,
              child: Text('${rating.toStringAsFixed(1)}+'),
            ),
      ],
      onChanged: (value) => controller.setMinRating(value ?? 0),
    );
  }

  Widget _sortDropdown(DoctorSearchController controller) {
    return DropdownButtonFormField<DoctorSort>(
      value: controller.sort,
      isExpanded: true,
      decoration: AppDecorations.inputDecoration(
        labelText: AppStrings.sortBy,
        prefixIcon: Icons.sort,
      ),
      items: const [
        DropdownMenuItem<DoctorSort>(
          value: DoctorSort.recommended,
          child: Text(AppStrings.sortRecommended),
        ),
        DropdownMenuItem<DoctorSort>(
          value: DoctorSort.highestRated,
          child: Text(AppStrings.sortHighestRated),
        ),
        DropdownMenuItem<DoctorSort>(
          value: DoctorSort.mostExperienced,
          child: Text(AppStrings.sortMostExperienced),
        ),
      ],
      onChanged: (value) {
        if (value != null) controller.setSort(value);
      },
    );
  }

  Widget _buildResults(DoctorSearchController controller) {
    if (controller.hasError) {
      return ErrorStateWidget(
        message: controller.errorMessage ?? AppStrings.doctorsLoadFailed,
        onRetry: controller.retry,
      );
    }

    if (controller.isLoading) {
      return const LoadingWidget(message: AppStrings.loadingDoctorsMsg);
    }

    final doctors = controller.results;
    if (doctors.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: AppStrings.noDoctorsFound,
        subtitle: AppStrings.doctorSearchEmpty,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      children: [
        _buildRecommendedShortcut(),
        const SizedBox(height: AppSizes.paddingSm),
        Text(
          '${doctors.length} ${AppStrings.doctorsFound}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSm),
        for (final doctor in doctors)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.paddingMd),
            child: DoctorCard(
              doctor: doctor,
              onTap: () => _openDetails(doctor),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendedShortcut() {
    return CustomCard(
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.doctorRecommendation);
      },
      child: Row(
        children: [
          const Icon(Icons.recommend_outlined, color: AppColors.primary),
          const SizedBox(width: AppSizes.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.recommendedDoctors,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXs),
                const Text(
                  AppStrings.doctorSearchSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }

  void _openDetails(Doctor doctor) {
    Navigator.of(context).pushNamed(
      AppRoutes.doctorDetails,
      arguments: DoctorDetailsArgs(doctor: doctor),
    );
  }
}

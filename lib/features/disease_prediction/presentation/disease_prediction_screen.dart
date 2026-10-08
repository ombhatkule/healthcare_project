import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import 'providers/disease_prediction_controller.dart';
import 'widgets/widgets.dart';

/// Disease Prediction screen (Phase 7J).
///
/// Lets the user search for and select symptoms, then run an experimental
/// research/educational prediction. The symptom catalog is fetched from the
/// backend `GET /api/symptoms` (single source of truth); the prediction is
/// run through [DiseasePredictionService] so the mock can be swapped for the
/// Flask REST API without UI changes.
class DiseasePredictionScreen extends StatefulWidget {
  const DiseasePredictionScreen({super.key});

  @override
  State<DiseasePredictionScreen> createState() =>
      _DiseasePredictionScreenState();
}

class _DiseasePredictionScreenState extends State<DiseasePredictionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handlePredict(BuildContext context) async {
    final controller = context.read<DiseasePredictionController>();

    if (controller.selectedSymptoms.isEmpty) {
      AppUtils.showSnackBar(context, AppStrings.noSymptomsSelected,
          isError: true);
      return;
    }

    await controller.predict();

    if (!context.mounted) return;
    if (controller.hasError) {
      AppUtils.showSnackBar(
        context,
        controller.errorMessage ?? AppStrings.predictionFailure,
        isError: true,
      );
      return;
    }
    if (controller.result != null) {
      Navigator.of(context).pushNamed(AppRoutes.predictionResult);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.predictionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: AppStrings.predictionHistoryTitle,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.predictionHistory),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          children: [
            _buildIntro(),
            const SizedBox(height: AppSizes.paddingMd),
            SymptomSearchField(
              controller: _searchController,
              onChanged: (value) => context
                  .read<DiseasePredictionController>()
                  .setSearchQuery(value),
              onClear: () {
                _searchController.clear();
                context
                    .read<DiseasePredictionController>()
                    .clearSearch();
                FocusScope.of(context).unfocus();
              },
            ),
            const SizedBox(height: AppSizes.paddingLg),
            SelectedSymptomsSection(
              symptoms: context.watch<DiseasePredictionController>()
                  .selectedSymptoms,
              onRemove: (symptom) => context
                  .read<DiseasePredictionController>()
                  .removeSymptom(symptom),
            ),
            const SizedBox(height: AppSizes.paddingLg),
            _buildAvailableSymptoms(context),
            const SizedBox(height: AppSizes.paddingLg),
            PredictionButton(
              isLoading: context.watch<DiseasePredictionController>()
                  .isPredicting,
              onPressed: () => _handlePredict(context),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            OutlinedButton.icon(
              onPressed:
                  context.watch<DiseasePredictionController>().isPredicting
                      ? null
                      : () {
                          _searchController.clear();
                          context
                              .read<DiseasePredictionController>()
                              .reset();
                        },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(AppStrings.clear),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  AppSizes.buttonHeight,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),
            const PredictionDisclaimer(
              message: AppStrings.predictionDisclaimer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.secondary.withAlpha(16),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_outlined,
                      color: AppColors.secondary, size: 20),
                  SizedBox(width: AppSizes.paddingSm),
                  Expanded(
                    child: Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingSm),
              Text(
                AppStrings.predictionIntro,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSm),
              Text(
                AppStrings.predictionNotDiagnosis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableSymptoms(BuildContext context) {
    final controller = context.watch<DiseasePredictionController>();

    if (controller.isCatalogLoading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.availableSymptoms,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSizes.paddingSm),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
            child: Text(
              AppStrings.analyzeSymptoms,
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ),
        ],
      );
    }

    if (controller.hasCatalogError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.availableSymptoms,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          Text(
            controller.catalogError ?? AppStrings.symptomsFailedToLoad,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<DiseasePredictionController>().retryLoadSymptoms(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(AppStrings.retry),
          ),
        ],
      );
    }

    final filtered = controller.filteredSymptoms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.availableSymptoms,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSm),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
            child: Text(
              'No symptoms found. Try a different search.',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          )
        else
          Wrap(
            spacing: AppSizes.paddingSm,
            runSpacing: AppSizes.paddingXs,
            children: filtered
                .map(
                  (s) => SymptomChip(
                    label: s.name,
                    selected: controller.isSelected(s),
                    onTap: () => context
                        .read<DiseasePredictionController>()
                        .toggleSymptom(s),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

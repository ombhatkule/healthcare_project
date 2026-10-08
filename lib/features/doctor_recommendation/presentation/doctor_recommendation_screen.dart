import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/models.dart';
import 'providers/doctor_recommendation_controller.dart';
import 'widgets/widgets.dart';

/// Shows the recommended doctors for a predicted condition (or a browsed
/// specialty) together with the mapped specialty context.
///
/// Args: [DoctorRecommendationArgs] — either a predicted disease (comes from
/// the prediction-result screen) or a selected specialty (comes from the
/// "Find a Doctor" screen). If neither is provided the fallback specialty
/// (General Physician) is shown.
class DoctorRecommendationScreen extends StatefulWidget {
  final DoctorRecommendationArgs? args;

  const DoctorRecommendationScreen({super.key, this.args});

  @override
  State<DoctorRecommendationScreen> createState() =>
      _DoctorRecommendationScreenState();
}

class _DoctorRecommendationScreenState extends State<DoctorRecommendationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<DoctorRecommendationController>();
      final args = widget.args;
      if (args?.predictedDisease != null &&
          args!.predictedDisease!.trim().isNotEmpty) {
        controller.loadForDisease(args.predictedDisease);
      } else if (args?.specialty != null &&
          args!.specialty!.trim().isNotEmpty) {
        controller.loadForSpecialty(args.specialty!);
      } else {
        controller.loadForSpecialty(
          DiseaseSpecialtyMapping.fallbackSpecialty,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DoctorRecommendationController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isFromPrediction
              ? AppStrings.recommendedDoctors
              : AppStrings.doctorSearchTitle,
        ),
      ),
      body: SafeArea(child: _buildBody(controller)),
    );
  }

  Widget _buildBody(DoctorRecommendationController controller) {
    if (controller.hasError) {
      return ErrorStateWidget(
        message: controller.errorMessage ?? AppStrings.doctorsLoadFailed,
        onRetry: controller.retry,
      );
    }

    if (controller.isLoading) {
      return const LoadingWidget(message: AppStrings.loadingDoctorsMsg);
    }

    if (controller.doctors.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.medical_services_outlined,
        title: AppStrings.noDoctorsFound,
        subtitle: AppStrings.noDoctorsFoundMessage,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      children: [
        if (controller.isFromPrediction) ...[
          _PredictionContextBanner(controller: controller),
          const SizedBox(height: AppSizes.paddingMd),
        ],
        Text(
          controller.activeSpecialty ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingXs),
        Text(
          AppStrings.doctorsMatchingSpecialty,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingMd),
        ...controller.doctors.map(
          (doctor) => DoctorCard(
            doctor: doctor,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.doctorDetails,
              arguments: DoctorDetailsArgs(doctor: doctor),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        const Text(
          AppStrings.recommendationNotMedicalAdvice,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Small banner showing the predicted condition -> recommended specialty.
class _PredictionContextBanner extends StatelessWidget {
  final DoctorRecommendationController controller;

  const _PredictionContextBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.basedOnPrediction,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppSizes.paddingXs),
          Text(
            controller.predictedDisease ?? '',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSizes.paddingSm),
          Text(
            AppStrings.recommendedSpecialtyLabel,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppSizes.paddingXs),
          Text(
            controller.recommendedSpecialty,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
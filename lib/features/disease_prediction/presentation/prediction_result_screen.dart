import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../doctor_recommendation/models/navigation_args.dart';
import 'providers/disease_prediction_controller.dart';
import 'widgets/widgets.dart';

/// Shows the prediction result after the user submits symptoms.
///
/// The result is clearly marked as a demo/mock prediction and includes a
/// medical disclaimer so it is never mistaken for a confirmed diagnosis.
class PredictionResultScreen extends StatelessWidget {
  const PredictionResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiseasePredictionController>();
    final result = controller.result;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.predictionResultTitle)),
      body: SafeArea(
        child: result == null
            ? const LoadingWidget(message: AppStrings.loading)
            : ListView(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                children: [
                  const SizedBox(height: AppSizes.paddingSm),
                  const Center(
                    child: Text(
                      AppStrings.predictionResultTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMd),
                  PredictionResultCard(result: result),
                  const SizedBox(height: AppSizes.paddingMd),
                  PrimaryButton(
                    label: AppStrings.findRecommendedDoctors,
                    icon: Icons.medical_services_outlined,
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.doctorRecommendation,
                        arguments: DoctorRecommendationArgs(
                          predictedDisease: result.prediction,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingLg),
                  PredictionDisclaimer(
                    message: result.disclaimer ?? AppStrings.predictionDisclaimer,
                  ),
                  const SizedBox(height: AppSizes.paddingLg),
                  PrimaryButton(
                    label: AppStrings.newPrediction,
                    icon: Icons.refresh,
                    onPressed: () {
                      controller.reset();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../models/prediction_result.dart';

/// Displays a prediction result.
///
/// Demo/mock results show a badge, the legacy confidence "percentage" and the
/// possible conditions list. Real Flask results show the possible condition,
/// the raw model score (never presented as a calibrated probability), the
/// top predictions and the backend disclaimer.
class PredictionResultCard extends StatelessWidget {
  final PredictionResult result;

  const PredictionResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.isDemo) ...[
            _Badge(
              icon: Icons.science_outlined,
              label: AppStrings.demoLabel,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSizes.paddingMd),
          ],
          _metric(
            label: result.isDemo
                ? 'Prediction'
                : AppStrings.predictionPossibleCondition,
            value: result.prediction,
            accent: AppColors.primary,
          ),
          const SizedBox(height: AppSizes.paddingMd),
          if (result.score != null)
            _metric(
              label: AppStrings.modelScore,
              value: result.modelScoreLabel,
              accent: AppColors.secondary,
            )
          else
            _metric(
              label: AppStrings.confidence,
              value: result.confidenceLabel,
              accent: AppColors.secondary,
            ),
          const SizedBox(height: AppSizes.paddingLg),
          if (result.topPredictions.isNotEmpty) ...[
            Text(
              AppStrings.topPredictions,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            ...result.topPredictions.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingXs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSizes.paddingSm),
                    Expanded(
                      child: Text(
                        '${t.disease} — ${t.scoreLabel}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),
          ] else if (result.possibleConditions.isNotEmpty) ...[
            Text(
              AppStrings.possibleConditions,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            ...result.possibleConditions.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingXs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSizes.paddingSm),
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),
          ],
          if (!result.isDemo) ...[
            Text(
              AppStrings.decisionSupportDisclaimer,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
          ],
          Text(
            result.disclaimer ?? AppStrings.predictionNotDiagnosis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
      ],
    );
  }
}

/// A small label badge (e.g. "Demo / Mock Prediction").
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
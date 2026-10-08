import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// The module's medical-safety disclaimer.
///
/// Shown on every screen in the Diet & Exercise module so no plan, exercise or
/// progress figure can ever be read as medical advice.
class WellnessDisclaimer extends StatelessWidget {
  final String? text;
  final bool compact;

  const WellnessDisclaimer({super.key, this.text, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      padding: EdgeInsets.all(compact ? AppSizes.paddingSm : AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          const SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: Text(
              text ?? AppStrings.dietExerciseDisclaimer,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
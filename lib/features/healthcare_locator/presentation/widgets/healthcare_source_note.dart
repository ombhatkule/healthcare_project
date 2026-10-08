import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// Attribution and disclaimer shown wherever facility data is listed.
class HealthcareSourceNote extends StatelessWidget {
  const HealthcareSourceNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      padding: const EdgeInsets.all(AppSizes.paddingSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: AppSizes.iconSm,
              color: AppColors.textSecondary),
          SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: Text(
              AppStrings.healthcareSourceNote,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
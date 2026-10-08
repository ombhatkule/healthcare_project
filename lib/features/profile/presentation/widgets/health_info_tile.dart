import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// A single row in the health information section showing a label, an optional
/// unit and the corresponding value.
class HealthInfoTile extends StatelessWidget {
  final String label;
  final String? value;
  final String? unit;

  const HealthInfoTile({
    super.key,
    required this.label,
    this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final raw = (value == null || value!.trim().isEmpty) ? null : value!.trim();
    final showPlaceholder = raw == null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingMd),
          if (showPlaceholder)
            const Text(
              AppStrings.notSpecified,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textHint,
              ),
            )
          else
            Text(
              unit != null ? '$raw $unit' : raw,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

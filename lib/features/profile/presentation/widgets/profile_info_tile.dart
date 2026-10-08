import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// A single row in the personal information section showing an icon, a label
/// and the corresponding value (falling back to a "not specified" state).
class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.trim().isEmpty)
        ? AppStrings.notSpecified
        : value!;
    final isEmpty = text == AppStrings.notSpecified;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryLight),
          const SizedBox(width: AppSizes.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isEmpty ? AppColors.textHint : AppColors.textPrimary,
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

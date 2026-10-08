import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// Simple section title matching the app's typography.
class SectionTitle extends StatelessWidget {
  final String label;

  const SectionTitle(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMd,
        AppSizes.paddingLg,
        AppSizes.paddingMd,
        AppSizes.paddingXs,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
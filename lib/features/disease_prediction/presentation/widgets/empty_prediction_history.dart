import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// Empty state shown when the user has no prediction history.
class EmptyPredictionHistory extends StatelessWidget {
  final String message;

  const EmptyPredictionHistory({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.history,
            size: 56,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSizes.paddingMd),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

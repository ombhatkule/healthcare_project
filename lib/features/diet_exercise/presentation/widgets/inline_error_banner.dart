import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// Inline, dismissible error banner for partial failures (e.g. a save that
/// could not reach Firestore). Content stays usable underneath it, and the
/// retry action re-runs the load without leaving the screen.
class InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;
  final bool isLoading;

  const InlineErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onDismiss,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      padding: const EdgeInsets.all(AppSizes.paddingSm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
              const SizedBox(width: AppSizes.paddingSm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Dismiss message',
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('diet_exercise_retry_action'),
              onPressed: isLoading ? null : onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(AppStrings.retry),
            ),
          ),
        ],
      ),
    );
  }
}
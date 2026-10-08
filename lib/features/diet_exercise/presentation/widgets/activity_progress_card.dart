import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// A single progress metric (water, exercise or activity) for the summary row.
class ActivityProgressCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final Color color;
  final String? supportingText;
  final VoidCallback? onTap;

  const ActivityProgressCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    this.color = AppColors.primary,
    this.supportingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: AppSizes.paddingXs),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingXs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (supportingText != null)
                Text(
                  supportingText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              const SizedBox(height: AppSizes.paddingSm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                child: LinearProgressIndicator(
                  value: safeProgress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
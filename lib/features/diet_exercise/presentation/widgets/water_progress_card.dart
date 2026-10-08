import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// Hydration tracker with increment / decrement controls.
///
/// The decrement button is disabled at zero so the counter can never go
/// negative, and the count is always shown as text as well as an icon.
class WaterProgressCard extends StatelessWidget {
  final int glasses;
  final int goal;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool enabled;

  const WaterProgressCard({
    super.key,
    required this.glasses,
    required this.goal,
    this.onIncrement,
    this.onDecrement,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (glasses / goal).clamp(0.0, 1.0);
    final reached = goal > 0 && glasses >= goal;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_drink_outlined, color: AppColors.info),
                const SizedBox(width: AppSizes.paddingSm),
                Expanded(
                  child: Text(
                    AppStrings.waterIntakeLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (reached)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 15,
                          color: AppColors.success),
                      SizedBox(width: AppSizes.paddingXs),
                      Text(
                        'Goal reached',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WaterButton(
                  key: const Key('water_decrement'),
                  icon: Icons.remove,
                  tooltip: AppStrings.decreaseWaterTooltip,
                  onPressed: enabled && glasses > 0 ? onDecrement : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Semantics(
                        liveRegion: true,
                        label: '$glasses of $goal ${AppStrings.glassesUnit} of water logged',
                        child: Text(
                          '$glasses / $goal',
                          key: const Key('water_count'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Text(
                        AppStrings.glassesUnit,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                _WaterButton(
                  key: const Key('water_increment'),
                  icon: Icons.add,
                  tooltip: AppStrings.increaseWaterTooltip,
                  onPressed: enabled ? onIncrement : null,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  reached ? AppColors.success : AppColors.info,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingXs),
            Text(
              '${AppStrings.waterGoalLabel}: $goal '
              '${AppStrings.glassesUnit} • ${AppStrings.generalGuidanceLabel}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _WaterButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton.filled(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceVariant,
          disabledForegroundColor: AppColors.textHint,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../models/models.dart';

/// A single exercise card with duration, difficulty and completion state.
///
/// Completion is communicated with an icon *and* text, never colour alone.
class ExerciseCard extends StatelessWidget {
  final ExerciseItem exercise;
  final bool isCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onToggleCompleted;
  final bool showCategory;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.isCompleted,
    this.onTap,
    this.onToggleCompleted,
    this.showCategory = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_outline
                          : exercise.category.icon,
                      color: isCompleted ? AppColors.success : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exercise.summaryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (showCategory)
                          Text(
                            exercise.category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onToggleCompleted != null)
                    Semantics(
                      label: isCompleted
                          ? '${exercise.name} completed. Tap to mark as not done.'
                          : 'Mark ${exercise.name} as completed',
                      button: true,
                      child: IconButton(
                        key: Key('exercise_complete_${exercise.id}'),
                        tooltip: isCompleted
                            ? 'Mark ${exercise.name} as not done'
                            : AppStrings.markCompletedLabel,
                        onPressed: onToggleCompleted,
                        icon: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isCompleted
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                      ),
                    )
                  else if (isCompleted)
                    Semantics(
                      label: '${exercise.name} completed',
                      child: const Icon(Icons.check_circle,
                          color: AppColors.success),
                    ),
                ],
              ),
              if (exercise.description.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingSm),
                Text(
                  exercise.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              if (isCompleted) ...[
                const SizedBox(height: AppSizes.paddingSm),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 15, color: AppColors.success),
                    const SizedBox(width: AppSizes.paddingXs),
                    Text(
                      AppStrings.completedLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
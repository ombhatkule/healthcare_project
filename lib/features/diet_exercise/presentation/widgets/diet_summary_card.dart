import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../models/models.dart';

/// Compact summary of today's diet plan shown on the main screen.
///
/// Only a preview of the meals is rendered here; the full plan lives on the
/// dedicated diet screen so this card stays readable on small screens.
class DietSummaryCard extends StatelessWidget {
  final DietPlan plan;
  final VoidCallback onViewFullPlan;

  const DietSummaryCard({
    super.key,
    required this.plan,
    required this.onViewFullPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = plan.meals.take(4).toList();

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
                const Icon(Icons.restaurant_menu_outlined,
                    color: AppColors.primary),
                const SizedBox(width: AppSizes.paddingSm),
                Expanded(
                  child: Text(
                    AppStrings.todaysDietPlanLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (plan.subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSizes.paddingXs),
              Text(
                plan.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.paddingSm),
            if (plan.isEmpty)
              const Text(
                'No meal suggestions available right now.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              )
            else
              ...preview.map(
                (meal) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingXs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          meal.slot.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          meal.foodSummary.isEmpty
                              ? meal.title
                              : meal.foodSummary,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (plan.approximateCalories != null) ...[
              const SizedBox(height: AppSizes.paddingXs),
              Text(
                '${AppStrings.approximateLabel}: about '
                '${plan.approximateCalories} kcal for the listed meals.',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textHint,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.paddingMd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewFullPlan,
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text(AppStrings.viewFullDietPlan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
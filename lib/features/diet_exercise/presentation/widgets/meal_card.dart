import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../models/models.dart';

/// One meal of the diet plan, listing foods with example servings.
///
/// Every quantity is prefixed with "Approximate" / "Example serving" wording so
/// the numbers are never read as a prescribed target.
class MealCard extends StatelessWidget {
  final Meal meal;

  const MealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final calories = meal.approximateCalories;

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
                Expanded(
                  child: Text(
                    meal.slot.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  meal.slot.hint,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            if (meal.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppSizes.paddingSm),
                child: Text(
                  'No suggestions for this meal.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              )
            else
              ...meal.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(top: AppSizes.paddingSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.circle,
                                size: 7, color: AppColors.primary),
                          ),
                          const SizedBox(width: AppSizes.paddingSm),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.serving.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: AppSizes.paddingMd, top: 2),
                          child: Text(
                            '${AppStrings.exampleServingLabel}: ${item.serving}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      if (item.nutritionNote.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: AppSizes.paddingMd, top: 2),
                          child: Text(
                            item.nutritionNote,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (calories != null) ...[
              const SizedBox(height: AppSizes.paddingSm),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '${AppStrings.approximateLabel}: ~$calories kcal',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
            if (meal.tip.isNotEmpty) ...[
              const SizedBox(height: AppSizes.paddingSm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: AppSizes.paddingSm),
                  Expanded(
                    child: Text(
                      meal.tip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
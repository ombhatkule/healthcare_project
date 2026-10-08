import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../models/prediction_history.dart';

/// A single prediction history entry.
class PredictionHistoryCard extends StatelessWidget {
  final PredictionHistory item;

  const PredictionHistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.paddingSm),
              Text(
                AppUtilsFormat.date(item.date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (item.isDemo)
                Text(
                  AppStrings.demoLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSm),
          Text(
            item.prediction,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingXs),
          Text(
            '${item.symptomCount} ${AppStrings.symptoms}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small internal date formatter to keep the widget self-contained.
abstract final class AppUtilsFormat {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${_months[date.month - 1]} ${date.year}';
  }
}

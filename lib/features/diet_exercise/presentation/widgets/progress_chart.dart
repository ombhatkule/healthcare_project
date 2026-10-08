import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../models/models.dart';

/// A dependency-free bar chart for the last seven days.
///
/// Plain Flutter widgets are used on purpose: the project has no chart package
/// and this is all the visualisation the progress screen needs.
class ProgressChart extends StatelessWidget {
  final List<DailyActivitySummary> data;
  final double Function(DailyActivitySummary day) valueOf;
  final String Function(double value) labelBuilder;
  final Color barColor;

  const ProgressChart({
    super.key,
    required this.data,
    required this.valueOf,
    required this.labelBuilder,
    this.barColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    var maxValue = 0.0;
    for (final day in data) {
      final value = valueOf(day);
      if (value > maxValue) maxValue = value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((day) {
              final value = valueOf(day).clamp(0.0, maxValue <= 0 ? 1 : maxValue);
              final ratio = maxValue <= 0 ? 0.0 : value / maxValue;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingXs,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        labelBuilder(valueOf(day)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingXs),
                      Container(
                        height: 72 * ratio.clamp(0.0, 1.0),
                        constraints: const BoxConstraints(minHeight: 3),
                        decoration: BoxDecoration(
                          color: ratio <= 0 ? AppColors.divider : barColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingXs),
                      Text(
                        _weekdayLabel(day.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// `2026-10-05` -> `Mon`.
  String _weekdayLabel(String dateKey) {
    final parsed = dateFromKey(dateKey);
    if (parsed == null) return '';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[parsed.weekday - 1];
  }
}
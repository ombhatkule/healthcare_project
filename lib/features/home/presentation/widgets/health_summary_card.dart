import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../models/health_summary_model.dart';

/// Displays a compact summary of the user's health.
/// Currently shows placeholder values only; no medical logic.
class HealthSummaryCard extends StatelessWidget {
  final HealthSummaryModel summary;

  const HealthSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _SummaryItem(
            icon: Icons.monitor_weight_outlined,
            label: 'BMI',
            value: summary.bmiLabel,
            color: AppColors.secondary,
          ),
          _verticalDivider(),
          _SummaryItem(
            icon: Icons.event_available_outlined,
            label: 'Last Check',
            value: summary.lastCheckLabel,
            color: AppColors.success,
          ),
          _verticalDivider(),
          _SummaryItem(
            icon: Icons.folder_outlined,
            label: 'Records',
            value: '${summary.medicalRecordsCount}',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.divider,
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

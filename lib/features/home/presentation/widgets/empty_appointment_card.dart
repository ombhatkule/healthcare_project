import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// Empty state shown when the user has no upcoming appointment.
class EmptyAppointmentCard extends StatelessWidget {
  final VoidCallback? onBook;

  const EmptyAppointmentCard({super.key, this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 40,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSizes.paddingSm),
          const Text(
            'No Upcoming Appointment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingXs),
          const Text(
            'Book an appointment with a doctor to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (onBook != null) ...[
            const SizedBox(height: AppSizes.paddingMd),
            OutlinedButton.icon(
              onPressed: onBook,
              icon: const Icon(Icons.event_available_outlined, size: 18),
              label: const Text('Book Appointment'),
            ),
          ],
        ],
      ),
    );
  }
}

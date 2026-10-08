import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../models/models.dart';

/// A single nearby facility row with its quick actions.
class HealthcarePlaceCard extends StatelessWidget {
  final HealthcarePlace place;
  final VoidCallback onViewDetails;
  final VoidCallback? onDirections;
  final VoidCallback? onCall;

  const HealthcarePlaceCard({
    super.key,
    required this.place,
    required this.onViewDetails,
    this.onDirections,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final color = place.type == HealthcarePlaceType.hospital
        ? AppColors.error
        : AppColors.accent;
    final distance = place.distanceLabel;
    final address = place.address;

    return CustomCard(
      onTap: onViewDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(place.type.icon, color: color),
              ),
              const SizedBox(width: AppSizes.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXs),
                    Row(
                      children: [
                        _TypeBadge(type: place.type, color: color),
                        if (distance != null) ...[
                          const SizedBox(width: AppSizes.paddingSm),
                          const Icon(
                            Icons.near_me_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            distance,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (address != null) ...[
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.paddingSm),
          Wrap(
            spacing: AppSizes.paddingSm,
            runSpacing: AppSizes.paddingXs,
            children: [
              TextButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.info_outline, size: AppSizes.iconSm),
                label: const Text(AppStrings.viewDetails),
              ),
              if (onDirections != null)
                TextButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined,
                      size: AppSizes.iconSm),
                  label: const Text(AppStrings.directionsAction),
                ),
              if (onCall != null)
                TextButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined, size: AppSizes.iconSm),
                  label: const Text(AppStrings.callAction),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final HealthcarePlaceType type;
  final Color color;

  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        type.singular,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
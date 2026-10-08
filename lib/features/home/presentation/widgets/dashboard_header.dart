import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// The welcome header shown at the top of the home dashboard.
///
/// Optionally exposes an AI Assistant entry action inside the card via
/// [onAiAssist]; the card keeps its existing look and simply gains a compact
/// "Ask AI Assistant" pill button below the greeting.
class DashboardHeader extends StatelessWidget {
  final String displayName;
  final VoidCallback? onAiAssist;

  const DashboardHeader({
    super.key,
    required this.displayName,
    this.onAiAssist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLg,
        AppSizes.paddingLg,
        AppSizes.paddingLg,
        AppSizes.paddingLg,
      ),
      margin: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  _initial(displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingMd),
              Expanded(
                child: Text(
                  'Hello, $displayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMd),
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          if (onAiAssist != null) ...[
            const SizedBox(height: AppSizes.paddingMd),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: InkWell(
                onTap: onAiAssist,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMd,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSizes.paddingXs),
                      Text(
                        AppStrings.aiWelcomeActionLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}

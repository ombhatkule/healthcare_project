import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// A "Assistant is thinking..." bubble shown while the AI reply is pending.
///
/// Uses three bouncing dots plus a label so the user knows a request is
/// processing without blocking the rest of the conversation.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingXs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingSm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _TypeDot(),
            _TypeDot(delay: Duration(milliseconds: 200)),
            _TypeDot(delay: Duration(milliseconds: 400)),
            SizedBox(width: AppSizes.paddingSm + 4),
            Text(
              'Assistant is thinking...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeDot extends StatelessWidget {
  final Duration delay;

  const _TypeDot({this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.paddingXs),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../models/chat_message.dart';

/// Displays a single chat message as a rounded speech bubble.
///
/// User messages are right-aligned on the primary color; assistant messages
/// are left-aligned on a white surface. Timestamps are shown in a small,
/// unobtrusive style for both roles.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    final bubbleColor = isUser ? AppColors.primary : AppColors.surface;
    final textColor = isUser ? Colors.white : AppColors.textPrimary;
    final timeColor = isUser ? Colors.white70 : AppColors.textHint;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppSizes.radiusLg),
      topRight: const Radius.circular(AppSizes.radiusLg),
      bottomLeft: Radius.circular(isUser ? AppSizes.radiusLg : AppSizes.radiusSm),
      bottomRight:
          Radius.circular(isUser ? AppSizes.radiusSm : AppSizes.radiusLg),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingXs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingSm + 2,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSizes.paddingXs),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: timeColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
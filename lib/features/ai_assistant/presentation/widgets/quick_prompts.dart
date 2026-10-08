import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// A single suggestion chip shown at the top of the assistant chat.
class QuickPrompt {
  final String label;
  final String message;

  const QuickPrompt({required this.label, required this.message});
}

/// A list of example questions users can tap to start a conversation.
///
/// Tapping a prompt sends it as a normal user query — the AI response is never
/// hardcoded here.
class QuickPrompts {
  static const List<QuickPrompt> prompts = [
    QuickPrompt(
      label: 'Latest prescription',
      message: 'What is in my latest prescription?',
    ),
    QuickPrompt(
      label: 'Next appointment',
      message: 'When is my next appointment?',
    ),
    QuickPrompt(
      label: 'My medical records',
      message: 'Explain my latest medical record.',
    ),
    QuickPrompt(
      label: 'Doctors visited',
      message: 'What doctors have I visited?',
    ),
    QuickPrompt(
      label: 'Prescription info',
      message: 'What does my prescription say?',
    ),
    QuickPrompt(
      label: 'Health information',
      message: 'Give me general health information.',
    ),
  ];

  /// Whether the quick prompt strip should be shown.
  static bool shouldShow({required bool isSending, required int messageCount}) {
    // Hide prompts while a request is in flight and once the user has
    // exchanged a few messages, to keep the conversation area clean.
    return !isSending && messageCount <= 4;
  }
}

/// A horizontal row of tappable quick-prompt chips.
class QuickPromptBar extends StatelessWidget {
  final ValueChanged<String> onPrompt;

  const QuickPromptBar({super.key, required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
        itemCount: QuickPrompts.prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.paddingSm),
        itemBuilder: (context, index) {
          final prompt = QuickPrompts.prompts[index];
          return ActionChip(
            label: Text(
              prompt.label,
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: AppColors.surfaceVariant,
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            onPressed: () => onPrompt(prompt.message),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// Bottom input bar for the AI chat: a rounded text field plus a send button.
///
/// The send action is disabled while [isSending] (a request is in flight) and
/// while the input is empty, preventing duplicate/empty submissions. The
/// keyboard remains fully supported: the field requests focus normally and the
/// Scaffold's `resizeToAvoidBottomInset` keeps the input above the keyboard.
class ChatInputBar extends StatefulWidget {
  final bool isSending;
  final ValueChanged<String> onSend;

  const ChatInputBar({
    super.key,
    required this.isSending,
    required this.onSend,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty && !widget.isSending;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingSm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _handleSend(),
                decoration: const InputDecoration(
                  hintText: 'Ask something...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMd,
                    vertical: AppSizes.paddingSm + 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppSizes.radiusFull),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppSizes.radiusFull),
                    ),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppSizes.radiusFull),
                    ),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.paddingSm),
            IconButton(
              onPressed: canSend ? _handleSend : null,
              tooltip: 'Send',
              icon: const Icon(Icons.send),
              iconSize: AppSizes.iconMd,
              color: canSend ? AppColors.primary : AppColors.textHint,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                disabledBackgroundColor: AppColors.surfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
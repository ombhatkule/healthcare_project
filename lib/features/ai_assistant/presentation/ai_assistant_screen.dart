import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/ai_assistant_controller.dart';
import 'widgets/widgets.dart';

/// The AI Healthcare Assistant screen.
///
/// All AI calls and data retrieval happen through [AiAssistantController];
/// this screen only renders conversation state and forwards user input.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AiAssistantController>().startSession();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send(String text) async {
    final userId = context.read<AuthProvider>().currentUid;
    await context
        .read<AiAssistantController>()
        .sendMessage(text, userId: userId);
    _scrollToBottom();
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _confirmClear() async {
    final confirmed = await AppUtils.showConfirmDialog(
      context,
      title: AppStrings.aiClearTitle,
      content: AppStrings.aiClearMessage,
      confirmText: AppStrings.aiClearConfirm,
      cancelText: AppStrings.cancel,
    );
    if (confirmed && mounted) {
      context.read<AiAssistantController>().clearConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AiAssistantController>();
    final uid = context.watch<AuthProvider>().currentUid;

    if (controller.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.aiAssistantTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: AppStrings.aiNewChatTooltip,
            onPressed: controller.isSending ? null : _confirmClear,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _DisclaimerBanner(),
            const SizedBox(height: AppSizes.paddingSm),
            if (QuickPrompts.shouldShow(
              isSending: controller.isSending,
              messageCount: controller.messageCount,
            ))
              QuickPromptBar(
                onPrompt: (prompt) {
                  FocusScope.of(context).unfocus();
                  _send(prompt);
                },
              ),
            const SizedBox(height: AppSizes.paddingXs),
            Expanded(child: _buildChatBody(controller)),
            if (controller.errorMessage != null)
              _AssistantErrorBar(controller: controller, userId: uid),
            ChatInputBar(
              isSending: controller.isSending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBody(AiAssistantController controller) {
    final messages = controller.messages;

    if (messages.isEmpty) {
      return const _EmptyConversation();
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
        itemCount: messages.length + (controller.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= messages.length) {
            return const TypingIndicator();
          }
          return MessageBubble(message: messages[index]);
        },
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSizes.paddingMd,
        AppSizes.paddingSm,
        AppSizes.paddingMd,
        0,
      ),
      padding: const EdgeInsets.all(AppSizes.paddingSm),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.info.withAlpha(60)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 16),
          SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: Text(
              AppStrings.aiDisclaimer,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline error bar shown when a send fails.
///
/// It renders [AiAssistantController.errorMessage] for *every* failure — network
/// problems as well as backend rejections such as an unconfigured AI provider
/// (HTTP 503), rate limits (429) or bad requests (400). Previously only
/// `showNetworkError` was rendered here, so a non-network backend error left the
/// chat looking stuck: the user bubble appeared and nothing else, with no
/// explanation at all.
class _AssistantErrorBar extends StatelessWidget {
  final AiAssistantController controller;
  final String? userId;

  const _AssistantErrorBar({required this.controller, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isNetworkError = controller.showNetworkError;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
      padding: const EdgeInsets.all(AppSizes.paddingSm),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isNetworkError ? Icons.wifi_off : Icons.error_outline,
            color: AppColors.error,
            size: 18,
          ),
          SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: Text(
              isNetworkError
                  ? AppStrings.aiNetworkError
                  : controller.errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: controller.isSending
                ? null
                : () => controller.retry(userId),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppColors.info,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              AppStrings.aiAssistantWelcome,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}